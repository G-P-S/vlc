/*****************************************************************************
 * macosx.m: MacOS X OpenGL provider
 *****************************************************************************
 * Copyright (C) 2001-2013 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Derk-Jan Hartman <hartman at videolan dot org>
 *          Eric Petit <titer@m0k.org>
 *          Benjamin Pracht <bigben at videolan dot org>
 *          Damien Fouilleul <damienf at videolan dot org>
 *          Pierre d'Herbemont <pdherbemont at videolan dot org>
 *          Felix Paul Kühne <fkuehne at videolan dot org>
 *          David Fuhrmann <david dot fuhrmann at googlemail dot com>
 *          Rémi Denis-Courmont
 *          Juho Vähä-Herttua <juhovh at iki dot fi>
 *          Laurent Aimar <fenrir _AT_ videolan _DOT_ org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

/*****************************************************************************
 * Preamble
 *****************************************************************************/

#define VLC_GP_GPU

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <dlfcn.h>

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <vlc_common.h>
#include <vlc_plugin.h>
#include <vlc_vout_display.h>
#include <vlc_opengl.h>
#include <vlc_dialog.h>
#include "opengl/vout_helper.h"

#define GLHW_TEXT N_("GL/GLES hw converter")
#define GLHW_LONGTEXT N_( \
    "Force an \"gl hw converter\" module.")

/**
 * Forward declarations
 */
static int Open (vlc_object_t *);
static void Close (vlc_object_t *);

static picture_pool_t *Pool (vout_display_t *vd, unsigned requested_count);
static void PictureRender (vout_display_t *vd, picture_t *pic, subpicture_t *subpicture);
static void PictureDisplay (vout_display_t *vd, picture_t *pic, subpicture_t *subpicture);
static int Control (vout_display_t *vd, int query, va_list ap);

static void *OurGetProcAddress(vlc_gl_t *, const char *);

static int OpenglLock (vlc_gl_t *gl);
static void OpenglUnlock (vlc_gl_t *gl);
static void OpenglSwap (vlc_gl_t *gl);

/**
 * Module declaration
 */
vlc_module_begin ()
    /* Will be loaded even without interface module. see voutgl.m */
    set_shortname ("Mac OS X")
    set_description (N_("Mac OS X OpenGL video output"))
    set_category (CAT_VIDEO)
    set_subcategory (SUBCAT_VIDEO_VOUT)
    set_capability ("vout display", 300)
    set_callbacks (Open, Close)
    add_module ("glhw", NULL, NULL,
                GLHW_TEXT, GLHW_LONGTEXT, true)

    add_shortcut ("macosx", "vout_macosx")
    add_glopts ()
vlc_module_end ()

/**
 * Obj-C protocol declaration that drawable-nsobject should follow
 */
@protocol VLCOpenGLVideoViewEmbedding <NSObject>
- (void)addVoutSubview:(NSView *)view;
- (void)removeVoutSubview:(NSView *)view;
@end

@interface VLCOpenGLVideoView : NSOpenGLView
{
    vout_display_t *vd;
    BOOL _hasPendingReshape;
}
- (void)setVoutDisplay:(vout_display_t *)vd;
- (void)setVoutFlushing:(BOOL)flushing;
@end


struct vout_display_sys_t
{
    VLCOpenGLVideoView *glView;
    id<VLCOpenGLVideoViewEmbedding> container;

    vout_window_t *embed;
    vlc_gl_t *gl;
    vout_display_opengl_t *vgl;

    picture_pool_t *pool;
    picture_t *current;
    bool has_first_frame;

    vout_display_place_t place;

    // gpu callbacks
    void (*gpuopen)(void *opaque, void *pDXDevice, unsigned *width, unsigned *height);
    void (*gpuclose)(void *opaque);
    void (*gpunewframe)(void *opaque, void *source, void *sourceRect);
    void* opaque;

    // FBO and texture storing the RGB texture of the last decoded frame
    GLuint fboId;
    GLuint textureId;
};

struct gl_sys
{
    CGLContextObj locked_ctx;
    VLCOpenGLVideoView *glView;

    // opengl context used to perform OpenGL operations
    NSOpenGLContext *nsopenglcontext;
};

static void *OurGetProcAddress(vlc_gl_t *gl, const char *name)
{
    VLC_UNUSED(gl);

    return dlsym(RTLD_DEFAULT, name);
}

static int Open (vlc_object_t *this)
{
    vout_display_t *vd = (vout_display_t *)this;
    vout_display_sys_t *sys = calloc (1, sizeof(*sys));

    if (!sys)
        return VLC_ENOMEM;

    @autoreleasepool {
        if (!CGDisplayUsesOpenGLAcceleration (kCGDirectMainDisplay))
            msg_Err (this, "no OpenGL hardware acceleration found. this can lead to slow output and unexpected results");

        vd->sys = sys;
        sys->pool = NULL;
        sys->embed = NULL;
        sys->vgl = NULL;
        sys->gl = NULL;
        sys->gpuopen = NULL;
        sys->gpuclose = NULL;
        sys->gpunewframe = NULL;
        sys->opaque = NULL;
        sys->glView = NULL;

        NSOpenGLContext *nscontext = NULL;

#ifdef VLC_GP_GPU
        // get gpu callbacks
        sys->gpuopen            = var_InheritAddress(vd, "vmem-gpuopen");
        sys->gpuclose           = var_InheritAddress(vd, "vmem-gpuclose");
        sys->gpunewframe        = var_InheritAddress(vd, "vmem-gpunewframe");
        sys->opaque             = var_InheritAddress(vd, "vmem-opaque");

        // call gpu open callback
        if (sys->gpuopen != NULL) {

            //TODO : get fboId from player
            //int *i_width = &vd->fmt.i_width;
            //msg_Err(vd, "before %i",*i_width);
            //sys->gpuopen(sys->opaque, &nscontext, &i_width, &vd->fmt.i_height);
            //msg_Err(vd, "after %i",*i_width);
            //msg_Err(vd, "sure %i",vd->fmt.i_width);

            // get NSOpenGLContext* instanciated from player
            sys->gpuopen(sys->opaque, &nscontext, &vd->fmt.i_width, &vd->fmt.i_height);

            // ensure to have a pointer to NSOpenGLContext class
            if (![nscontext isKindOfClass:[NSOpenGLContext class]]) {
                msg_Err(vd, "pointer from libvlc gpuopen() is not a NSOpenGLContext*.");
                goto error;
            }
        }
        else {
            msg_Err(vd, "you are using VLC_GP_GPU version, callback gpuopen is mandatory.");
            goto error;
        }
#else
        /* Get the drawable object */
        id container = var_CreateGetAddress (vd, "drawable-nsobject");
        if (container)
            vout_display_DeleteWindow (vd, NULL);
        else {
            sys->embed = vout_display_NewWindow (vd, VOUT_WINDOW_TYPE_NSOBJECT);
            if (sys->embed)
                container = sys->embed->handle.nsobject;

            if (!container) {
                msg_Err(vd, "No drawable-nsobject nor vout_window_t found, passing over.");
                goto error;
            }
        }

        /* This will be released in Close(), on
         * main thread, after we are done using it. */
        sys->container = [container retain];

        /* Get our main view*/
        [VLCOpenGLVideoView performSelectorOnMainThread:@selector(getNewView:)
                                             withObject:[NSValue valueWithPointer:&sys->glView]
                                          waitUntilDone:YES];
        if (!sys->glView) {
            msg_Err(vd, "Initialization of open gl view failed");
            goto error;
        }

        [sys->glView setVoutDisplay:vd];

        /* We don't wait, that means that we'll have to be careful about releasing
         * container.
         * That's why we'll release on main thread in Close(). */
        if ([(id)container respondsToSelector:@selector(addVoutSubview:)])
            [(id)container performSelectorOnMainThread:@selector(addVoutSubview:)
                                            withObject:sys->glView
                                         waitUntilDone:NO];
        else if ([container isKindOfClass:[NSView class]]) {
            NSView *parentView = container;
            [parentView performSelectorOnMainThread:@selector(addSubview:)
                                         withObject:sys->glView
                                      waitUntilDone:NO];
            [sys->glView performSelectorOnMainThread:@selector(setFrameToBoundsOfView:)
                                          withObject:[NSValue valueWithPointer:parentView]
                                       waitUntilDone:NO];
        } else {
            msg_Err(vd, "Invalid drawable-nsobject object. drawable-nsobject must either be an NSView or comply to the @protocol VLCOpenGLVideoViewEmbedding.");
            goto error;
        }
#endif

        /* Initialize common OpenGL video display */
        sys->gl = vlc_object_create(this, sizeof(*sys->gl));

        if( unlikely( !sys->gl ) )
            goto error;

        struct gl_sys *glsys = sys->gl->sys = malloc(sizeof(struct gl_sys));
        if( unlikely( !sys->gl->sys ) )
        {
            vlc_object_release(sys->gl);
            goto error;
        }
        glsys->locked_ctx = NULL;
        glsys->glView = sys->glView;
        sys->gl->makeCurrent = OpenglLock;
        sys->gl->releaseCurrent = OpenglUnlock;
        sys->gl->swap = OpenglSwap;
        sys->gl->getProcAddress = OurGetProcAddress;

        var_Create(vd->obj.parent, "macosx-glcontext", VLC_VAR_ADDRESS);
#ifdef VLC_GP_GPU
        var_SetAddress(vd->obj.parent, "macosx-glcontext", [nscontext CGLContextObj]);
#else
        var_SetAddress(vd->obj.parent, "macosx-glcontext", [[sys->glView openGLContext] CGLContextObj]);
#endif

        // keep pointer to the context, do not destroy it
        glsys->nsopenglcontext = nscontext;

        const vlc_fourcc_t *subpicture_chromas;

        if (vlc_gl_MakeCurrent(sys->gl) != VLC_SUCCESS)
        {
            msg_Err(vd, "Can't attach gl context");
            goto error;
        }
        sys->vgl = vout_display_opengl_New (&vd->fmt, &subpicture_chromas, sys->gl,
                                            &vd->cfg->viewpoint);
        vlc_gl_ReleaseCurrent(sys->gl);
        if (!sys->vgl) {
            msg_Err(vd, "Error while initializing opengl display.");
            goto error;
        }

        /* */
        vout_display_info_t info = vd->info;
        info.has_pictures_invalid = false;
        info.subpicture_chromas = subpicture_chromas;

        /* Setup vout_display_t once everything is fine */
        vd->info = info;

        vd->pool = Pool;
        vd->prepare = PictureRender;
        vd->display = PictureDisplay;
        vd->control = Control;
        
#ifdef VLC_GP_GPU
        // use a FBO with EXT to use framebuffers in OpenGL 2.1
        if (vlc_gl_MakeCurrent(sys->gl) != VLC_SUCCESS) {
            msg_Err(vd, " Can't attach gl context");
            goto error;
        }
        GLuint fboId;
        GLenum target = GL_TEXTURE_2D;
        glGenFramebuffersEXT(1, &fboId);
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboId);
        glGenTextures(1, &sys->textureId);
        glBindTexture(target, sys->textureId);
        glTexParameteri(target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexImage2D(target, 0, GL_RGBA8, vd->fmt.i_width, vd->fmt.i_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, target, sys->textureId, 0);
        glBindFramebufferEXT( GL_FRAMEBUFFER_EXT, 0 );
        glBindTexture(target, 0);
        vlc_gl_ReleaseCurrent(sys->gl);

        // store FBO id to draw into it in vout_helper.c::DrawWithShaders
        sys->fboId = fboId;
        vout_display_opengl_SetFboId(sys->vgl, fboId);

        /*
        // Debug infos
        // check opengl errors
        GLenum err;
        while((err = glGetError()) != GL_NO_ERROR) msg_Err(vd, "### Have to clean gl errors before creating FBO... glerror = %i", err);
        // check opengl version and extension
        const GLubyte * strVersion;
        const GLubyte * strExt;
        float myGLVersion;
        bool isEXT;
        strVersion = glGetString (GL_VERSION);
        sscanf((char *)strVersion, "%f", &myGLVersion);
        strExt = glGetString (GL_EXTENSIONS);
        isEXT = (bool)gluCheckExtension ((const GLubyte*)"GL_EXT_framebuffer_object",strExt);
        GLenum stat = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
        // FBO should be ready, try to fill with color...
        msg_Err(vd, "### GL INFO : try to fill FBO with color...");
        glBindFramebufferEXT(GL_DRAW_FRAMEBUFFER_EXT, fboId);
        glClearColor(0.0,1.0,0.0,1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        glSwapAPPLE();
        glBindFramebufferEXT( GL_DRAW_FRAMEBUFFER_EXT, 0 );
        msg_Err(vd, "### GL INFO : strVersion = %s",strVersion);
        msg_Err(vd, "### GL INFO : GL_EXT_framebuffer_object is available = %s",isEXT?"true":"false");
        msg_Err(vd, "### GL INFO : glGenFramebuffersEXT = %p", glGenFramebuffersEXT);
        msg_Err(vd, "### GL INFO : glBindFramebufferEXT = %p", glBindFramebufferEXT);
        msg_Err(vd, "### GL INFO : FBO glCheckFramebufferStatus = %i", stat);
        msg_Err(vd, "### GL INFO : GL ERROR CODE 36053 : GL_FRAMEBUFFER_COMPLETE");
        msg_Err(vd, "### GL INFO : GL ERROR CODE 33305 : GL_FRAMEBUFFER_UNDEFINED");
        msg_Err(vd, "### GL INFO : GL ERROR CODE 1286 : GL_INVALID_FRAMEBUFFER_OPERATION");
        msg_Err(vd, "### GL INFO : texture id TO SHARE = %i", sys->textureId);

        */
#else
        vout_display_SendEventDisplaySize (vd, vd->fmt.i_visible_width, vd->fmt.i_visible_height);
#endif

        return VLC_SUCCESS;

    error:
        Close(this);
        return VLC_EGENERIC;
    }
}

void Close (vlc_object_t *this)
{
    vout_display_t *vd = (vout_display_t *)this;
    vout_display_sys_t *sys = vd->sys;

    // call gpu close callback
    if (vd != NULL && vd->sys != NULL && vd->sys->gpuclose != NULL) vd->sys->gpuclose(sys->opaque);

    @autoreleasepool {
#ifndef VLC_GP_GPU
        [sys->glView setVoutDisplay:nil];

        var_Destroy (vd, "drawable-nsobject");
        if ([(id)sys->container respondsToSelector:@selector(removeVoutSubview:)])
        /* This will retain sys->glView */
            [(id)sys->container performSelectorOnMainThread:@selector(removeVoutSubview:)
                                                 withObject:sys->glView
                                              waitUntilDone:NO];

        /* release on main thread as explained in Open() */
        [(id)sys->container performSelectorOnMainThread:@selector(release)
                                             withObject:nil
                                          waitUntilDone:NO];
        [sys->glView performSelectorOnMainThread:@selector(removeFromSuperview)
                                      withObject:nil
                                   waitUntilDone:NO];
#endif
        var_Destroy(vd->obj.parent, "macosx-glcontext");
        if (sys->vgl != NULL)
        {
            vlc_gl_MakeCurrent(sys->gl);
#ifdef VLC_GP_GPU
            // delete texture and FBO
            glDeleteTextures(1, &sys->textureId);
            glDeleteFramebuffersEXT(1, &sys->fboId);
#endif
            vout_display_opengl_Delete (sys->vgl);
            vlc_gl_ReleaseCurrent(sys->gl);
        }

        if (sys->gl != NULL)
        {
            assert(((struct gl_sys *)sys->gl->sys)->locked_ctx == NULL);
            free(sys->gl->sys);
            vlc_object_release(sys->gl);
        }

#ifndef VLC_GP_GPU
        [sys->glView release];
#endif

        if (sys->embed)
            vout_display_DeleteWindow (vd, sys->embed);
        free (sys);
    }
}

/*****************************************************************************
 * vout display callbacks
 *****************************************************************************/

static picture_pool_t *Pool (vout_display_t *vd, unsigned requested_count)
{
    vout_display_sys_t *sys = vd->sys;

    if (!sys->pool && vlc_gl_MakeCurrent(sys->gl) == VLC_SUCCESS)
    {
        sys->pool = vout_display_opengl_GetPool (sys->vgl, requested_count);
        vlc_gl_ReleaseCurrent(sys->gl);
    }
    return sys->pool;
}

static void PictureRender (vout_display_t *vd, picture_t *pic, subpicture_t *subpicture)
{

    vout_display_sys_t *sys = vd->sys;

    if (vlc_gl_MakeCurrent(sys->gl) == VLC_SUCCESS)
    {
        vout_display_opengl_Prepare (sys->vgl, pic, subpicture);
        vlc_gl_ReleaseCurrent(sys->gl);
    }
}

static void PictureDisplay (vout_display_t *vd, picture_t *pic, subpicture_t *subpicture)
{
    vout_display_sys_t *sys = vd->sys;

#ifdef VLC_GP_GPU
    if (vlc_gl_MakeCurrent(sys->gl) == VLC_SUCCESS)
    {
        vout_display_opengl_Display(sys->vgl, &vd->source);
        sys->gpunewframe(sys->opaque, &sys->textureId, 0);
        vlc_gl_ReleaseCurrent(sys->gl);
    }
#else
    [sys->glView setVoutFlushing:YES];
    if (vlc_gl_MakeCurrent(sys->gl) == VLC_SUCCESS)
    {
        vout_display_opengl_Display (sys->vgl, &vd->source);
        vlc_gl_ReleaseCurrent(sys->gl);
    }
    [sys->glView setVoutFlushing:NO];
#endif
    picture_Release (pic);
    sys->has_first_frame = true;

    if (subpicture)
        subpicture_Delete(subpicture);
}

static int Control (vout_display_t *vd, int query, va_list ap)
{
#ifdef VLC_GP_GPU
    // do nothing about window stuff
    return VLC_SUCCESS;
#else
    vout_display_sys_t *sys = vd->sys;

    if (!vd->sys)
        return VLC_EGENERIC;

    @autoreleasepool {
        switch (query)
        {
            case VOUT_DISPLAY_CHANGE_DISPLAY_FILLED:
            case VOUT_DISPLAY_CHANGE_ZOOM:
            case VOUT_DISPLAY_CHANGE_SOURCE_ASPECT:
            case VOUT_DISPLAY_CHANGE_SOURCE_CROP:
            case VOUT_DISPLAY_CHANGE_DISPLAY_SIZE:
            {
                const vout_display_cfg_t *cfg;

                if (query == VOUT_DISPLAY_CHANGE_SOURCE_ASPECT || query == VOUT_DISPLAY_CHANGE_SOURCE_CROP) {
                    cfg = vd->cfg;
                } else {
                    cfg = (const vout_display_cfg_t*)va_arg (ap, const vout_display_cfg_t *);
                }

                /* we always use our current frame here, because we have some size constraints
                 in the ui vout provider */
                vout_display_cfg_t cfg_tmp = *cfg;
                /* on HiDPI displays, the point bounds don't equal the actual pixel based bounds */
                NSRect bounds = [sys->glView convertRectToBacking:[sys->glView bounds]];
                cfg_tmp.display.width = bounds.size.width;
                cfg_tmp.display.height = bounds.size.height;

                /* Reverse vertical alignment as the GL tex are Y inverted */
                if (cfg_tmp.align.vertical == VOUT_DISPLAY_ALIGN_TOP)
                    cfg_tmp.align.vertical = VOUT_DISPLAY_ALIGN_BOTTOM;
                else if (cfg_tmp.align.vertical == VOUT_DISPLAY_ALIGN_BOTTOM)
                    cfg_tmp.align.vertical = VOUT_DISPLAY_ALIGN_TOP;

                vout_display_place_t place;
                vout_display_PlacePicture (&place, &vd->source, &cfg_tmp, false);
                @synchronized (sys->glView) {
                    sys->place = place;
                }

                if (vlc_gl_MakeCurrent (sys->gl) != VLC_SUCCESS)
                    return VLC_EGENERIC;
                vout_display_opengl_SetWindowAspectRatio(sys->vgl, (float)place.width / place.height);

                /* For resize, we call glViewport in reshape and not here.
                 This has the positive side effect that we avoid erratic sizing as we animate every resize. */
                if (query != VOUT_DISPLAY_CHANGE_DISPLAY_SIZE)
                    // x / y are top left corner, but we need the lower left one
                    vout_display_opengl_Viewport(sys->vgl, place.x,
                                                 cfg_tmp.display.height - (place.y + place.height),
                                                 place.width, place.height);
                vlc_gl_ReleaseCurrent (sys->gl);

                return VLC_SUCCESS;
            }

            case VOUT_DISPLAY_HIDE_MOUSE: /* FIXME: dead code */
            {
                [NSCursor setHiddenUntilMouseMoves: YES];
                return VLC_SUCCESS;
            }

            case VOUT_DISPLAY_CHANGE_VIEWPOINT:
                return vout_display_opengl_SetViewpoint (sys->vgl,
                    &va_arg (ap, const vout_display_cfg_t* )->viewpoint);

            case VOUT_DISPLAY_RESET_PICTURES:
                vlc_assert_unreachable ();
            default:
                msg_Err (vd, "Unknown request in Mac OS X vout display");
                return VLC_EGENERIC;
        }
    }
#endif
}

/*****************************************************************************
 * vout opengl callbacks
 *****************************************************************************/
static int OpenglLock (vlc_gl_t *gl)
{
    struct gl_sys *sys = gl->sys;

#ifdef VLC_GP_GPU
    assert(sys->locked_ctx == NULL);

    NSOpenGLContext *context = sys->nsopenglcontext;
#else
    if (![sys->glView respondsToSelector:@selector(openGLContext)])
        return 1;

    assert(sys->locked_ctx == NULL);

    NSOpenGLContext *context = [sys->glView openGLContext];
#endif

    CGLContextObj cglcntx = [context CGLContextObj];

    CGLError err = CGLLockContext (cglcntx);
    if (kCGLNoError == err) {
        sys->locked_ctx = cglcntx;
        [context makeCurrentContext];
        return 0;
    }
    return 1;
}

static void OpenglUnlock (vlc_gl_t *gl)
{
    struct gl_sys *sys = gl->sys;
    CGLUnlockContext (sys->locked_ctx);
    sys->locked_ctx = NULL;
}

static void OpenglSwap (vlc_gl_t *gl)
{
    struct gl_sys *sys = gl->sys;
#ifdef VLC_GP_GPU
    [sys->nsopenglcontext flushBuffer];
#else
    [[sys->glView openGLContext] flushBuffer];
#endif
}

/*****************************************************************************
 * Our NSView object
 *****************************************************************************/
@implementation VLCOpenGLVideoView

#define VLCAssertMainThread() assert([[NSThread currentThread] isMainThread])


+ (void)getNewView:(NSValue *)value
{
    id *ret = [value pointerValue];
    *ret = [[self alloc] init];
}

/**
 * Gets called by the Open() method.
 */
- (id)init
{
    VLCAssertMainThread();

    /* Warning - this may be called on non main thread */

    NSOpenGLPixelFormatAttribute attribs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        //NSOpenGLPFANoRecovery, // WARNING : this option make context unsharable with Qt context
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAWindow,
        NSOpenGLPFAAllowOfflineRenderers,
        0
    };

    NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];

    if (!fmt)
        return nil;

    self = [super initWithFrame:NSMakeRect(0,0,10,10) pixelFormat:fmt];
    [fmt release];

    if (!self)
        return nil;

    /* enable HiDPI support */
    [self setWantsBestResolutionOpenGLSurface:YES];

    /* request our screen's HDR mode (introduced in OS X 10.11) */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
    if ([self respondsToSelector:@selector(setWantsExtendedDynamicRangeOpenGLSurface:)]) {
        [self setWantsExtendedDynamicRangeOpenGLSurface:YES];
    }
#pragma clang diagnostic pop

    /* Swap buffers only during the vertical retrace of the monitor.
     http://developer.apple.com/documentation/GraphicsImaging/
     Conceptual/OpenGL/chap5/chapter_5_section_44.html */
    GLint params[] = { 1 };
    CGLSetParameter ([[self openGLContext] CGLContextObj], kCGLCPSwapInterval, params);

    [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidChangeScreenParametersNotification
                                                      object:[NSApplication sharedApplication]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification) {
                                                      [self performSelectorOnMainThread:@selector(reshape)
                                                                             withObject:nil
                                                                          waitUntilDone:NO];
                                                  }];

    [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

/**
 * Gets called by the Open() method.
 */
- (void)setFrameToBoundsOfView:(NSValue *)value
{
    NSView *parentView = [value pointerValue];
    [self setFrame:[parentView bounds]];
}

/**
 * Gets called by the Close and Open methods.
 * (Non main thread).
 */
- (void)setVoutDisplay:(vout_display_t *)aVd
{
    @synchronized(self) {
        vd = aVd;
    }
}

/**
 * Gets called when the vout will aquire the lock and flush.
 * (Non main thread).
 */
- (void)setVoutFlushing:(BOOL)flushing
{
    if (!flushing)
        return;
    @synchronized(self) {
        _hasPendingReshape = NO;
    }
}

/**
 * Can -drawRect skip rendering?.
 */
- (BOOL)canSkipRendering
{
    VLCAssertMainThread();

    @synchronized(self) {
        BOOL hasFirstFrame = vd && vd->sys->has_first_frame;
        return !_hasPendingReshape && hasFirstFrame;
    }
}


/**
 * Local method that locks the gl context.
 */
- (BOOL)lockgl
{
    VLCAssertMainThread();
    NSOpenGLContext *context = [self openGLContext];
    CGLError err = CGLLockContext ([context CGLContextObj]);
    if (err == kCGLNoError)
        [context makeCurrentContext];
    return err == kCGLNoError;
}

/**
 * Local method that unlocks the gl context.
 */
- (void)unlockgl
{
    VLCAssertMainThread();
    CGLUnlockContext ([[self openGLContext] CGLContextObj]);
}

/**
 * Local method that force a rendering of a frame.
 * This will get called if Cocoa forces us to redraw (via -drawRect).
 */
- (void)render
{
    VLCAssertMainThread();

    // We may have taken some times to take the opengl Lock.
    // Check here to see if we can just skip the frame as well.
    if ([self canSkipRendering])
        return;

    BOOL hasFirstFrame;
    @synchronized(self) { // vd can be accessed from multiple threads
        hasFirstFrame = vd && vd->sys->has_first_frame;
    }

    if (hasFirstFrame)
        // This will lock gl.
        vout_display_opengl_Display (vd->sys->vgl, &vd->source);
    else
        glClear (GL_COLOR_BUFFER_BIT);
}

/**
 * Method called by Cocoa when the view is resized.
 */
- (void)reshape
{
    VLCAssertMainThread();

    /* on HiDPI displays, the point bounds don't equal the actual pixel based bounds */
    NSRect bounds = [self convertRectToBacking:[self bounds]];
    vout_display_place_t place;

    @synchronized(self) {
        if (vd) {
            vout_display_cfg_t cfg_tmp = *(vd->cfg);
            cfg_tmp.display.width  = bounds.size.width;
            cfg_tmp.display.height = bounds.size.height;

            vout_display_PlacePicture (&place, &vd->source, &cfg_tmp, false);
            vd->sys->place = place;
            vout_display_SendEventDisplaySize (vd, bounds.size.width, bounds.size.height);
        }
    }

    if ([self lockgl]) {
        // x / y are top left corner, but we need the lower left one
        glViewport (place.x, bounds.size.height - (place.y + place.height), place.width, place.height);

        @synchronized(self) {
            // This may be cleared before -drawRect is being called,
            // in this case we'll skip the rendering.
            // This will save us for rendering two frames (or more) for nothing
            // (one by the vout, one (or more) by drawRect)
            _hasPendingReshape = YES;
        }

        [self unlockgl];

        [super reshape];
    }
}

/**
 * Method called by Cocoa when the view is resized or the location has changed.
 * We just need to make sure we are locking here.
 */
- (void)update
{
    VLCAssertMainThread();
    BOOL success = [self lockgl];
    if (!success)
        return;

    [super update];

    [self unlockgl];
}

/**
 * Method called by Cocoa to force redraw.
 */
- (void)drawRect:(NSRect) rect
{
    VLCAssertMainThread();

    if ([self canSkipRendering])
        return;

    BOOL success = [self lockgl];
    if (!success)
        return;

    [self render];

    [self unlockgl];
}

- (void)renewGState
{
    // Comment take from Apple GLEssentials sample code:
    // https://developer.apple.com/library/content/samplecode/GLEssentials
    //
    // OpenGL rendering is not synchronous with other rendering on the OSX.
    // Therefore, call disableScreenUpdatesUntilFlush so the window server
    // doesn't render non-OpenGL content in the window asynchronously from
    // OpenGL content, which could cause flickering.  (non-OpenGL content
    // includes the title bar and drawing done by the app with other APIs)

    // In macOS 10.13 and later, window updates are automatically batched
    // together and this no longer needs to be called (effectively a no-op)
    [[self window] disableScreenUpdatesUntilFlush];

    [super renewGState];
}

- (BOOL)isOpaque
{
    return YES;
}

#pragma mark -
#pragma mark Mouse handling

- (void)mouseDown:(NSEvent *)o_event
{
    @synchronized (self) {
        if (vd) {
            if ([o_event type] == NSLeftMouseDown && !([o_event modifierFlags] &  NSControlKeyMask)) {
                if ([o_event clickCount] <= 1)
                    vout_display_SendEventMousePressed (vd, MOUSE_BUTTON_LEFT);
            }
        }
    }

    [super mouseDown:o_event];
}

- (void)otherMouseDown:(NSEvent *)o_event
{
    @synchronized (self) {
        if (vd)
            vout_display_SendEventMousePressed (vd, MOUSE_BUTTON_CENTER);
    }

    [super otherMouseDown: o_event];
}

- (void)mouseUp:(NSEvent *)o_event
{
    @synchronized (self) {
        if (vd) {
            if ([o_event type] == NSLeftMouseUp)
                vout_display_SendEventMouseReleased (vd, MOUSE_BUTTON_LEFT);
        }
    }

    [super mouseUp: o_event];
}

- (void)otherMouseUp:(NSEvent *)o_event
{
    @synchronized (self) {
        if (vd)
            vout_display_SendEventMouseReleased (vd, MOUSE_BUTTON_CENTER);
    }

    [super otherMouseUp: o_event];
}

- (void)mouseMoved:(NSEvent *)o_event
{
    /* on HiDPI displays, the point bounds don't equal the actual pixel based bounds */
    NSPoint ml = [self convertPoint: [o_event locationInWindow] fromView: nil];
    NSRect videoRect = [self bounds];
    BOOL b_inside = [self mouse: ml inRect: videoRect];

    ml = [self convertPointToBacking: ml];
    videoRect = [self convertRectToBacking: videoRect];

    if (b_inside) {
        @synchronized (self) {
            if (vd) {
                vout_display_SendMouseMovedDisplayCoordinates(vd, ORIENT_NORMAL,
                                                              (int)ml.x, videoRect.size.height - (int)ml.y,
                                                              &vd->sys->place);
            }
        }
    }

    [super mouseMoved: o_event];
}

- (void)mouseDragged:(NSEvent *)o_event
{
    [self mouseMoved: o_event];
    [super mouseDragged: o_event];
}

- (void)otherMouseDragged:(NSEvent *)o_event
{
    [self mouseMoved: o_event];
    [super otherMouseDragged: o_event];
}

- (void)rightMouseDragged:(NSEvent *)o_event
{
    [self mouseMoved: o_event];
    [super rightMouseDragged: o_event];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)mouseDownCanMoveWindow
{
    return YES;
}

@end
