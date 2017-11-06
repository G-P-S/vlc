
#include <stdio.h>

#include <stdint.h>
#include <stdlib.h>

#include <Windows.h>
#include "WinMainParameters.h"
#include <inttypes.h>

#define ssize_t  SSIZE_T
#include <vlc/vlc.h>

#include "mmsoglwin1.h"
#include <GL\gl.h>
#include <GL\glu.h>
#include "gl\glext.h"
#include "gl\glcorearb.h"
#include "gl\wglext.h"

#define WINBOOL bool
//#include "d3dx9tex.h" d3dx9.lib

int done = 0;
int video_setup_done = 0;
libvlc_media_player_t *media_player = NULL;
uint8_t *videoBuffer = 0;
uint8_t *audioBuffer = 0;
unsigned int videoBufferSize = 0;
 unsigned int audioBufferSize = 0;

 extern TCHAR szTitle[MAX_LOADSTRING];						/*!< Title bar text for this application. */
 extern TCHAR szWindowClass[MAX_LOADSTRING];				/*!< The main window class name. */

 extern HWND     hWnd;
 HINSTANCE hInstance; //for window creation
 int nCmdShow; //for window creation


 extern GLuint m_h264TextureArray[MAXVIDEOCLIPS];			/*!< GL texture for video N */
 extern HANDLE m_hH264DeviceArray[MAXVIDEOCLIPS];			/*!< Device value returned from NV_DX_Interop for video N */
 extern  HANDLE m_hH264TextureArray[MAXVIDEOCLIPS];			/*!< Texture value returned from NV_DX_Interop for video N */

 HANDLE ghMutex;

 extern bool bindtex;
 bool bindtextureVLC(IDirect3DDevice9* pDX9, LPDIRECT3DSURFACE9 dxSurf, HANDLE  dxHandle, GLuint texture, HANDLE& hDevice, HANDLE& hTexture);
 bool unbindtexture();

 //Frames
#ifdef VTUNE_axeFRAME
#include <ittnotify.h>
 static __itt_domain* pDomain_Dec = __itt_domain_createA("Domain_DecodeConvert");
#endif


int mainVLC(int argc, char **argv);
using namespace WinMainParameters;

D3DLOCKED_RECT lockedRect;
 int ID = VID; //DX surface ID

int video_width, video_height; //from VLC

/*!< Variables for computing fps. */
unsigned long Last = 0;
unsigned long Now = 0;
unsigned int DecTime = 0;
extern int fps;
extern int framecounter;


IDirect3DDevice9* vlc_DX9dev = NULL; //from VLC

IDirect3DSurface9* vlc_DX9surf = NULL;  //from VLC
IDirect3DSurface9* vlc_pSurface = NULL;
HANDLE vlc_SharedHandle = NULL;


void vlc_player_avcodec_hack_cb(void *data, unsigned *errCode) {}

void gpuopen(void *opaque,
	void *pDXDevice,
	unsigned *width,
	unsigned *height)
{
	vlc_DX9dev = (IDirect3DDevice9*)pDXDevice;

	D3DSURFACE_DESC pDesc;
	/**/HRESULT hr = vlc_DX9dev->CreateOffscreenPlainSurface(*width, *height, D3DFMT_X8R8G8B8,  
		D3DPOOL_DEFAULT,
		&vlc_pSurface, &vlc_SharedHandle);
	vlc_pSurface->GetDesc(&pDesc);

	bindtex  = bindtextureVLC(vlc_DX9dev, vlc_pSurface, vlc_SharedHandle, m_h264TextureArray[0], m_hH264DeviceArray[0], m_hH264TextureArray[0]); //Bind a DirectX surface to an OpenGL texture 
	
}

void gpuclose(void *data)
{
	unbindtexture();
}

void gpunewframe(void *opaque,
	void *source,
	void *sourceRect)
{
	static int framecounter_dec = 0; 
	static unsigned long Last = 0;
	static unsigned long Now = 0;
	static unsigned int DecTime = 0;

	//for fps calc
	if (framecounter_dec == 0){
		Last = GetTickCount();
	}
	else{
		Now = GetTickCount();
		DecTime += (unsigned int)(Now - Last);
		Last = Now;
	}
	
	if (framecounter_dec == 60) //here 60 influences precision only
	{
		if (DecTime) *((int*)opaque)  = framecounter_dec * 1000 / DecTime;
		framecounter_dec = 0;
		DecTime = 0;
	}
	framecounter_dec++;

	//DX part

	vlc_DX9surf = (IDirect3DSurface9*)source;

	D3DSURFACE_DESC pDesc;
	//vlc_pSurface->GetDesc(&pDesc);



#if 1
	HRESULT hr;
	hr = vlc_DX9dev->BeginScene();
	if (FAILED(hr))
		return;

	hr = vlc_DX9dev->StretchRect(vlc_DX9surf, NULL, vlc_pSurface, NULL, D3DTEXF_NONE);
	if (FAILED(hr)) {
		MessageBox(NULL, L"THE StretchRect failed", L"failed", MB_OK);
		return;
	}

	hr = vlc_DX9dev->EndScene();
	if (FAILED(hr)){
		return; //need it if the function continues
	}
#endif
	//HRESULT hh = D3DXSaveSurfaceToFile(_T("c:\\temp\\dx9.bmp"), D3DXIFF_BMP, vlc_pSurface, NULL, NULL);
	 
	display();

}

const char *videoclip = {
	"c:\\GoPro\\" 
	//"FullHD_25fps.mp4" }; 
	//"UHD_48fps.mp4" }; 
	"UHD_60fps.mp4" }; //UHD_48fps.mp4
	//"FullHD_25fps.mp4" }; //UHD_48fps.mp4

/*To examine the image quality, try using the mouse wheel to zoom on the textures, use the arrow keys to pan as needed.*/

int main(int argc, char **argv)
{
	// Use the functions from WinMainParameters.h to get the values that would've been passed to WinMain.
	// Note that these functions are in the WinMainParameters namespace.
	hInstance = GetHInstance();
	HINSTANCE hPrevInstance = GetHPrevInstance();
	LPWSTR lpCmdLine = GetLPCmdLine();
	nCmdShow = GetNCmdShow();

	// Assert that the values returned are expected.
	assert(hInstance != nullptr);
	assert(hPrevInstance == nullptr);
	assert(lpCmdLine != nullptr);

	LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadString(hInstance, IDC_MMSOGLWIN, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);


	//dirty !!!!!!!!!!!!!!!!!!!but ok for our  sample purpose
	//video_width =  1920; 
	//video_height = 960; 
	video_width =  3840; 
	video_height =  1920; 


	if (!InitInstance(hInstance, nCmdShow)) {
		return FALSE;
	}

	// VLC pointers
	libvlc_instance_t *vlcInstance;
	void *pUserData = 0;

	const char * const vlc_args[] = {
		//"--no-audio",
		"-I", "dummy", // Don't use any interface
	//"--ignore-config", // Don't use VLC's config
		"--no-plugins-cache",
		"--extraintf=logger",//Log anything
		//"--verbose=2", // Be verbose
		//"-vvv",    
		//"--vout" ,	"vmem"
	};

	// We launch VLC
	vlcInstance = libvlc_new(sizeof(vlc_args) / sizeof(vlc_args[0]), vlc_args);

	media_player = libvlc_media_player_new(vlcInstance);

#define OGL
#ifdef OGL
	 libvlc_video_set_gpu_callbacks(media_player,
		gpuopen,
		gpuclose,
		gpunewframe,
		&fps);

	 libvlc_video_set_avcodec_hack_callback(media_player, vlc_player_avcodec_hack_cb, &fps);
#endif

	 //create the special "fake" window for vlc
	HWND hWnd_vlc = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW |
		 WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
		 0,0, video_width, video_height,  NULL, NULL, hInstance, NULL);

	//ShowWindow(hWnd_vlc, SW_HIDE);
	libvlc_media_player_set_hwnd(media_player, hWnd_vlc); 

	libvlc_media_t *media = libvlc_media_new_path(vlcInstance, videoclip);
	
    libvlc_media_add_option(media, ":avcodec-hw=dxva2");
	libvlc_media_add_option(media,  ":avcodec-threads=1"); //it is being set automatically if hw decoding in use

	libvlc_media_player_set_media(media_player, media);
	libvlc_media_player_play(media_player);
	
	//OOOOOOOOOOOOOOOOO          OUR MAIN LOOP          OOOOOOOOOOOOOOOO
	_tWinMain_ (hInstance, hPrevInstance, lpCmdLine, nCmdShow);
	//OOOOOOOOOOOOOOOOO        OOOOOOOOOOOOOOOOOOOOOOOOOOOO

	libvlc_media_player_stop(media_player);
	libvlc_media_release(media);

	return 0;
}




