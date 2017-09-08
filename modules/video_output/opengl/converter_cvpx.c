/*****************************************************************************
 * converter_cvpx.c: OpenGL Apple CVPX opaque converter
 *****************************************************************************
 * Copyright (C) 2017 VLC authors and VideoLAN
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "converter.h"
#include "../../codec/vt_utils.h"

#if TARGET_OS_IPHONE
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <CoreVideo/CVOpenGLESTextureCache.h>
struct gl_sys
{
    CVEAGLContext locked_ctx;
};
#else
#include <IOSurface/IOSurface.h>
struct gl_sys
{
    CGLContextObj locked_ctx;
};
#endif

struct priv
{
    picture_t *last_pic;
#if TARGET_OS_IPHONE
    CVOpenGLESTextureCacheRef cache;
#endif
};

#if TARGET_OS_IPHONE
/* CVOpenGLESTextureCache version (ios) */
static int
tc_cvpx_update(const opengl_tex_converter_t *tc, GLuint *textures,
               const GLsizei *tex_width, const GLsizei *tex_height,
               picture_t *pic, const size_t *plane_offset)
{
    (void) plane_offset;
    struct priv *priv = tc->priv;

    CVPixelBufferRef pixelBuffer = cvpxpic_get_ref(pic);

    for (unsigned i = 0; i < tc->tex_count; ++i)
    {
        tc->vt->ActiveTexture(GL_TEXTURE0 + i);

        CVOpenGLESTextureRef texture;
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault, priv->cache, pixelBuffer, NULL,
            tc->tex_target, tc->texs[i].internal, tex_width[i], tex_height[i],
            tc->texs[i].format, tc->texs[i].type, i, &texture);
        if (err != noErr)
        {
            msg_Err(tc->gl,
                    "CVOpenGLESTextureCacheCreateTextureFromImage failed: %d",
                    err);
            return VLC_EGENERIC;
        }

        textures[i] = CVOpenGLESTextureGetName(texture);
        tc->vt->BindTexture(tc->tex_target, textures[i]);
        tc->vt->TexParameteri(tc->tex_target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        tc->vt->TexParameteri(tc->tex_target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        tc->vt->TexParameterf(tc->tex_target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        tc->vt->TexParameterf(tc->tex_target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        CFRelease(texture);
    }

    if (priv->last_pic != pic)
    {
        if (priv->last_pic != NULL)
            picture_Release(priv->last_pic);
        priv->last_pic = picture_Hold(pic);
    }
    return VLC_SUCCESS;
}

#else
/* IOSurface version (macos) */
static int
tc_cvpx_update(const opengl_tex_converter_t *tc, GLuint *textures,
               const GLsizei *tex_width, const GLsizei *tex_height,
               picture_t *pic, const size_t *plane_offset)
{
    (void) plane_offset;
    struct priv *priv = tc->priv;
    struct gl_sys *glsys = tc->gl->sys;

    CVPixelBufferRef pixelBuffer = cvpxpic_get_ref(pic);

    // make interop IOSurfaceRef (native decoded frame) to OpenGL
    IOSurfaceRef surface = CVPixelBufferGetIOSurface(pixelBuffer);

    for (unsigned i = 0; i < tc->tex_count; ++i)
    {
        tc->vt->ActiveTexture(GL_TEXTURE0 + i);
        tc->vt->BindTexture(tc->tex_target, textures[i]);

        CGLError err =
            CGLTexImageIOSurface2D(glsys->locked_ctx, tc->tex_target,
                                   tc->texs[i].internal,
                                   tex_width[i], tex_height[i],
                                   tc->texs[i].format,
                                   tc->texs[i].type,
                                   surface, i);
        if (err != kCGLNoError)
        {
            msg_Err(tc->gl, "CGLTexImageIOSurface2D error: %d: %s\n", i,
                    CGLErrorString(err));
            return VLC_EGENERIC;
        }
    }

    if (priv->last_pic != pic)
    {
        if (priv->last_pic != NULL)
            picture_Release(priv->last_pic);
        priv->last_pic = picture_Hold(pic);
    }

    return VLC_SUCCESS;
}
#endif

static void
Close(vlc_object_t *obj)
{
    opengl_tex_converter_t *tc = (void *)obj;
    struct priv *priv = tc->priv;

    if (priv->last_pic != NULL)
        picture_Release(priv->last_pic);
#if TARGET_OS_IPHONE
    CFRelease(priv->cache);
#endif
    free(tc->priv);
}

static int
Open(vlc_object_t *obj)
{
    opengl_tex_converter_t *tc = (void *) obj;
    if (tc->fmt.i_chroma != VLC_CODEC_CVPX_UYVY
     && tc->fmt.i_chroma != VLC_CODEC_CVPX_NV12
     && tc->fmt.i_chroma != VLC_CODEC_CVPX_I420
     && tc->fmt.i_chroma != VLC_CODEC_CVPX_BGRA)
        return VLC_EGENERIC;

    struct priv *priv = calloc(1, sizeof(struct priv));
    if (unlikely(priv == NULL))
        return VLC_ENOMEM;

#if TARGET_OS_IPHONE
    const GLenum tex_target = GL_TEXTURE_2D;

    {
        struct gl_sys *glsys = tc->gl->sys;
        CVReturn err =
            CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL,
                                         glsys->locked_ctx, NULL, &priv->cache);
        if (err != noErr)
        {
            msg_Err(tc->gl, "CVOpenGLESTextureCacheCreate failed: %d", err);
            free(priv);
            return VLC_EGENERIC;
        }
    }
    tc->handle_texs_gen = true;
#else
    const GLenum tex_target = GL_TEXTURE_RECTANGLE;
#endif

    GLuint fragment_shader;
    switch (tc->fmt.i_chroma)
    {
        case VLC_CODEC_CVPX_UYVY:
            /* Generate a VLC_CODEC_VYUY shader in order to use the "gbr"
             * swizzling. Indeed, the Y, Cb and Cr color channels within the
             * GL_RGB_422_APPLE format are mapped into the existing green, blue
             * and red color channels, respectively. cf. APPLE_rgb_422 khronos
             * extenstion. */

            fragment_shader =
                opengl_fragment_shader_init(tc, tex_target, VLC_CODEC_VYUY,
                                            COLOR_SPACE_UNDEF);
            tc->texs[0].internal = GL_RGB;
            tc->texs[0].format = GL_RGB_422_APPLE;
            tc->texs[0].type = GL_UNSIGNED_SHORT_8_8_APPLE;
            tc->texs[0].w = tc->texs[0].h = (vlc_rational_t) { 1, 1 };
            break;
        case VLC_CODEC_CVPX_NV12:
        {
            fragment_shader =
                opengl_fragment_shader_init(tc, tex_target, VLC_CODEC_NV12,
                                            COLOR_SPACE_UNDEF);
            break;
        }
        case VLC_CODEC_CVPX_I420:
            fragment_shader =
                opengl_fragment_shader_init(tc, tex_target, VLC_CODEC_I420,
                                            COLOR_SPACE_UNDEF);
            break;
        case VLC_CODEC_CVPX_BGRA:
            fragment_shader =
                opengl_fragment_shader_init(tc, tex_target, VLC_CODEC_RGB32,
                                            COLOR_SPACE_UNDEF);
            tc->texs[0].internal = GL_RGBA;
            tc->texs[0].format = GL_BGRA;
#if TARGET_OS_IPHONE
            tc->texs[0].type = GL_UNSIGNED_BYTE;
#else
            tc->texs[0].type = GL_UNSIGNED_INT_8_8_8_8_REV;
#endif
            break;
        default:
            vlc_assert_unreachable();
    }

    if (fragment_shader == 0)
    {
        free(priv);
        return VLC_EGENERIC;
    }

    tc->priv              = priv;
    tc->pf_update         = tc_cvpx_update;
    tc->fshader           = fragment_shader;

    return VLC_SUCCESS;
}

vlc_module_begin ()
    set_description("Apple OpenGL CVPX converter")
    set_capability("glconv", 1)
    set_callbacks(Open, Close)
    set_category(CAT_VIDEO)
    set_subcategory(SUBCAT_VIDEO_VOUT)
vlc_module_end ()
