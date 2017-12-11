/*
Copyright (c) 2016, Intel Corporation All Rights Reserved.
.*/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

//#include "stdafx.h"
#include "mmsoglwin1.h"

#include <GL\gl.h>
#include <GL\glu.h>
#include "gl\glext.h"
#include "gl\glcorearb.h"
#include "gl\wglext.h"


#ifdef _DEBUG
//#include <DxErr.h>
//#pragma comment(lib, "dxerr.lib")
#endif

extern int video_width, video_height; //we get it from  vlc
static int firstframe = 1;
#define GET_TEXTURE
void SaveAsBMP(const char *fileName)
{
	FILE *file;
	unsigned long imageSize;
	GLbyte *data = NULL;
	GLint viewPort[4];
	GLenum lastBuffer;
	BITMAPFILEHEADER bmfh;
	BITMAPINFOHEADER bmih;
	bmfh.bfType = 'MB';
	bmfh.bfReserved1 = 0;
	bmfh.bfReserved2 = 0;
	bmfh.bfOffBits = 54;
#ifdef GET_SCREEN
	glGetIntegerv(GL_VIEWPORT, viewPort);
	imageSize = ((viewPort[2] + ((4 - (viewPort[2] % 4)) % 4))*viewPort[3] * 3) + 2;
	bmfh.bfSize = imageSize + sizeof(bmfh) + sizeof(bmih);
	data = (GLbyte*)malloc(imageSize);
	glPixelStorei(GL_PACK_ALIGNMENT, 4);
	glPixelStorei(GL_PACK_ROW_LENGTH, 0);
	glPixelStorei(GL_PACK_SKIP_ROWS, 0);
	glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
	glPixelStorei(GL_PACK_SWAP_BYTES, 1);
	glGetIntegerv(GL_READ_BUFFER, (GLint*)&lastBuffer);
	glReadBuffer(GL_FRONT);
	glReadPixels(0, 0, viewPort[2], viewPort[3], GL_BGR, GL_UNSIGNED_BYTE, data);
	data[imageSize - 1] = 0;
	data[imageSize - 2] = 0;
	glReadBuffer(lastBuffer);
#endif
#ifdef GET_TEXTURE
	imageSize = video_width * video_height * 4;
	bmfh.bfSize = imageSize + sizeof(bmfh) + sizeof(bmih);
	data = (GLbyte*)calloc(imageSize, sizeof(GLbyte));

	glGetTexImage(GL_TEXTURE_2D, 0, GL_BGR, GL_UNSIGNED_BYTE, data);
	viewPort[2] = video_width;
	viewPort[3] = video_height;
#endif

	file = fopen(fileName, "wb");
	bmih.biSize = 40;
	bmih.biWidth = viewPort[2];
	bmih.biHeight = viewPort[3];
	bmih.biPlanes = 1;
	bmih.biBitCount = 24;
	bmih.biCompression = 0;
	bmih.biSizeImage = imageSize;
	bmih.biXPelsPerMeter = 45089;
	bmih.biYPelsPerMeter = 45089;
	bmih.biClrUsed = 0;
	bmih.biClrImportant = 0;
	fwrite(&bmfh, sizeof(bmfh), 1, file);
	fwrite(&bmih, sizeof(bmih), 1, file);
	fwrite(data, imageSize, 1, file);
	free(data);
	fclose(file);
}


#define CREATEOGLPFN(PFN,FUNC) \
	extern PFN FUNC; \
	PFN FUNC = NULL;

CREATEOGLPFN(PFNGLCREATEPROGRAMPROC,glCreateProgram);
CREATEOGLPFN(PFNGLDELETEPROGRAMPROC,glDeleteProgram);
CREATEOGLPFN(PFNGLUSEPROGRAMPROC,glUseProgram);
CREATEOGLPFN(PFNGLATTACHSHADERPROC,glAttachShader);
CREATEOGLPFN(PFNGLDETACHSHADERPROC,glDetachShader);
CREATEOGLPFN(PFNGLLINKPROGRAMPROC,glLinkProgram);
CREATEOGLPFN(PFNGLGETPROGRAMIVPROC,glGetProgramiv);
CREATEOGLPFN(PFNGLGETSHADERINFOLOGPROC,glGetShaderInfoLog);
CREATEOGLPFN(PFNGLGETUNIFORMLOCATIONPROC,glGetUniformLocation);
CREATEOGLPFN(PFNGLUNIFORM1IPROC,glUniform1i);
CREATEOGLPFN(PFNGLUNIFORM1IVPROC,glUniform1iv);
CREATEOGLPFN(PFNGLUNIFORM2IVPROC,glUniform2iv);
CREATEOGLPFN(PFNGLUNIFORM3IVPROC,glUniform3iv);
CREATEOGLPFN(PFNGLUNIFORM4IVPROC,glUniform4iv);
CREATEOGLPFN(PFNGLUNIFORM1FPROC,glUniform1f);
CREATEOGLPFN(PFNGLUNIFORM1FVPROC,glUniform1fv);
CREATEOGLPFN(PFNGLUNIFORM2FVPROC,glUniform2fv);
CREATEOGLPFN(PFNGLUNIFORM3FVPROC,glUniform3fv);
CREATEOGLPFN(PFNGLUNIFORM4FVPROC,glUniform4fv);
CREATEOGLPFN(PFNGLUNIFORMMATRIX4FVPROC,glUniformMatrix4fv);
CREATEOGLPFN(PFNGLGETATTRIBLOCATIONPROC,glGetAttribLocation);
CREATEOGLPFN(PFNGLVERTEXATTRIB1FPROC,glVertexAttrib1f);
CREATEOGLPFN(PFNGLVERTEXATTRIB1FVPROC,glVertexAttrib1fv);
CREATEOGLPFN(PFNGLVERTEXATTRIB2FVPROC,glVertexAttrib2fv);
CREATEOGLPFN(PFNGLVERTEXATTRIB3FVPROC,glVertexAttrib3fv);
CREATEOGLPFN(PFNGLVERTEXATTRIB4FVPROC,glVertexAttrib4fv);
CREATEOGLPFN(PFNGLENABLEVERTEXATTRIBARRAYPROC,glEnableVertexAttribArray);
CREATEOGLPFN(PFNGLBINDATTRIBLOCATIONPROC,glBindAttribLocation);
CREATEOGLPFN(PFNGLACTIVETEXTUREPROC,glActiveTexture);
CREATEOGLPFN(PFNGLCREATESHADERPROC,glCreateShader);
CREATEOGLPFN(PFNGLDELETESHADERPROC,glDeleteShader);
CREATEOGLPFN(PFNGLSHADERSOURCEPROC,glShaderSource);
CREATEOGLPFN(PFNGLCOMPILESHADERPROC,glCompileShader);
CREATEOGLPFN(PFNGLGETSHADERIVPROC,glGetShaderiv);
CREATEOGLPFN(PFNGLGENBUFFERSPROC,glGenBuffers);
CREATEOGLPFN(PFNGLBINDBUFFERPROC,glBindBuffer);
CREATEOGLPFN(PFNGLBUFFERDATAPROC,glBufferData);
CREATEOGLPFN(PFNGLVERTEXATTRIBPOINTERPROC,glVertexAttribPointer);
CREATEOGLPFN(PFNWGLDXSETRESOURCESHAREHANDLENVPROC,wglDXSetResourceShareHandleNV);
CREATEOGLPFN(PFNWGLDXOPENDEVICENVPROC,wglDXOpenDeviceNV);
CREATEOGLPFN(PFNWGLDXCLOSEDEVICENVPROC,wglDXCloseDeviceNV);
CREATEOGLPFN(PFNWGLDXREGISTEROBJECTNVPROC, wglDXRegisterObjectNV);
CREATEOGLPFN(PFNWGLDXUNREGISTEROBJECTNVPROC,wglDXUnregisterObjectNV);
CREATEOGLPFN(PFNWGLDXOBJECTACCESSNVPROC,wglDXObjectAccessNV);
CREATEOGLPFN(PFNWGLDXLOCKOBJECTSNVPROC,wglDXLockObjectsNV);
CREATEOGLPFN(PFNWGLDXUNLOCKOBJECTSNVPROC,wglDXUnlockObjectsNV);



#define D3DFMT_NV12 (D3DFORMAT)MAKEFOURCC('N','V','1','2')
#define D3DFMT_YV12 (D3DFORMAT)MAKEFOURCC('Y','V','1','2')

extern picture_sys_t* vlc_DX9pic; //from VLC
extern IDirect3DDevice9* vlc_DX9dev; //from VLC

extern IDirect3DSurface9* vlc_pSurface;
extern HANDLE vlc_SharedHandle;

bool bindtex = 0;
HWND        hWnd = NULL;



int fps = 0;
int framecounter = 0;

HINSTANCE hInst;									/*!< Current hInst for our application.  */
TCHAR szTitle[MAX_LOADSTRING];						/*!< Title bar text for OpenGL window. */
TCHAR szWindowClass[MAX_LOADSTRING];				/*!< The main window class name for OpenGL window.. */
HDC hDC;											/*!< Handle to device context. */
HGLRC hRC;											/*!< Handle to OpenGL context. */
bool m_bTextureInitialized = false;					/*!< Texture init flag. */
int m_cx, m_cy;										/*!< Width and height of the window frame during resizing. */
float nZoom = 1.0;									/*!< A zoom value that is tied to the mouse wheel. */
float xoffsetcurrent = 0.0f;						/*!< Application variable to track x offset. */
float yoffsetcurrent = 0.0f;						/*!< Application variable to track y offset. */
float offsetincrement = 0.01f;						/*!< Increment that panning moves when you press arrow keys. */
float apptexcoordscalar = 100000.0f;				/*!< Application value for scalar multiplier for texture coordinates. */
float appxtexcoordmultiplier = (float)NUMVIDEOROW;	/*!< Application value for number videos in each row*/
float appytexcoordmultiplier = (float)NUMVIDEOCOL;  /*!< Application value for number videos in each column*/
float appnumvideos = (float)MAXVIDEOCLIPS;
float tileincrement = 1.0f;

GLuint m_h264TextureArray[MAXVIDEOCLIPS];			/*!< GL texture for video N */
HANDLE m_hH264DeviceArray[MAXVIDEOCLIPS];			/*!< Device value returned from NV_DX_Interop for video N */
HANDLE m_hH264TextureArray[MAXVIDEOCLIPS];			/*!< Texture value returned from NV_DX_Interop for video N */
GLuint testdtexArray[MAXVIDEOCLIPS];				/*!< dtex[N] Handle to texture sampler. */

GLuint testxoffset = 0;								/*!< xoffset Handle to vertex shader. */
GLuint testyoffset = 0;								/*!< yoffset Handle vertex shader. */
GLuint glvertexshader = 0;										/*!< The vertex shader for this application. */
GLuint glfragmentshader = 0;										/*!< The fragment shader for this application. */
GLuint shadercombinedprogram = 0;						/*!< The final shader program for this application. */

GLuint texcoordscalar = 0;							/*!< Scalar multiplier for texture coordinates. */
GLuint xtexcoordmultiplier = 0;						/*!< Number videos in each row*/
GLuint ytexcoordmultiplier = 0;						/*!< Number videos in each column*/
GLuint numvideos = 0;								/*!< Total number of videos*/

//! Vertex shader for this program.
//! This is a simple vertex shader.  Uniform variables xoffset and yoffset are used to modify the geometry position based on user input from the arrow keys to give a simple panning feature.  Combined with zoom (attached to mouse wheel) this allows user to zoom in on the video data to observe quality at a closer level in a simple manner. See USESHADER in stdafx.h.  Comment out USESHADER to render without the fragment or vertex shader loaded. */
const char* vertexshaderstring =
"uniform float xoffset;"
"uniform float yoffset;"
"varying vec2 vTexCoord;"
"void main(void)"
"{"
"   vec4 a = gl_Vertex;"
"   a.x = a.x*(-1.0) + xoffset;"
"   a.y = a.y + yoffset;"
"   vTexCoord = gl_MultiTexCoord0.xy;"
"   gl_Position = a;"
"}";

//! Fragment shader for this program.
//! This is a simple fragment shader that tiles the videos to the screen.  Uniform variable array dtex[] is an array of texture samplers.  An array is use to dynamically choose what video to sample from at runtime.  This avoid extra texture reads in the fragment shader.  The number of tiles is hard coded to 6 but could be parameterized if needed.  Alternatively, you can turn off the shader and not use it.  See USESHADER in stdafx.h.  Comment out USESHADER to render without the fragment or vertex shader loaded. */
const char* fragmentshaderstring =
"#version 400\n"
"out vec4 frag_colour;"
"varying vec2 vTexCoord;"
"uniform sampler2D dtex[6];"
"uniform float texcoordscalar;"
"uniform float xtexcoordmultiplier;"
"uniform float ytexcoordmultiplier;"
"uniform float numvideos;"
"void main () {"
"  vec2 finaltexcoords = vec2(0.0,0.0);"
"  float modcoordsx = vTexCoord.x*texcoordscalar;"
"  modcoordsx = modcoordsx/(texcoordscalar/xtexcoordmultiplier);"
"  modcoordsx = floor(modcoordsx);"
"  float modcoordsy = vTexCoord.y*texcoordscalar;"
"  modcoordsy = modcoordsy/(texcoordscalar/ytexcoordmultiplier);"
"  modcoordsy = floor(modcoordsy);"
"  highp int testindex = int(mod(modcoordsx + xtexcoordmultiplier*modcoordsy, numvideos));"
"  finaltexcoords = vec2((vTexCoord.x - (modcoordsx/xtexcoordmultiplier))*xtexcoordmultiplier,(vTexCoord.y - (modcoordsy/ytexcoordmultiplier))*ytexcoordmultiplier);"
"  frag_colour = texture2D(dtex[testindex], finaltexcoords);"
"}";



wchar_t buffer[256]; //for fps display

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK About(HWND, UINT, WPARAM, LPARAM);
HWND CreateOpenGLWindow(TCHAR* title, int x, int y, int width, int height, BYTE type, DWORD flags, HINSTANCE hInstance);

void display();
void setupglfuncptrs();
void cleanupogl();
void creatOGLtexture(void);
bool createshaders();
bool unbindtexture();

/**
* _tWinMain() - Main application loop.
*/
int /*APIENTRY*/ _tWinMain_(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPTSTR lpCmdLine, _In_ int nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
	MSG msg;
	HACCEL hAccelTable;
/*	LoadString(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
	LoadString(hInstance, IDC_MMSOGLWIN, szWindowClass, MAX_LOADSTRING);
	MyRegisterClass(hInstance);
 
	 if (!InitInstance (hInstance, nCmdShow)) {
		return FALSE;
	}*/

	hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_MMSOGLWIN));

	unsigned int Last = 0;
	unsigned int Now = 0;
	Last = GetTickCount();
	while (GetMessage(&msg, NULL, 0, 0)) {
		 if(bindtex) display();
		if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
		InvalidateRect( msg.hwnd, NULL, FALSE );

		//display fps in window title 
		if (fps) wsprintfW(buffer, L"mmsoglwin DECODING %d fps", fps);

		SetWindowText(msg.hwnd,buffer);
	}
	return (int) msg.wParam;

}
/**
* MyRegisterClass() - Register this window application.
* @param hInstance Handle to current application instance.
* @return If the function succeeds, the return value is a class atom that uniquely identifies the class being registered.
*/
ATOM MyRegisterClass(HINSTANCE hInstance)
{
	WNDCLASSEX wcex;
	wcex.cbSize = sizeof(WNDCLASSEX);
	wcex.style			= CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc	= WndProc;
	wcex.cbClsExtra		= 0;
	wcex.cbWndExtra		= 0;
	wcex.hInstance		= hInstance;
	wcex.hIcon			= LoadIcon(hInstance, MAKEINTRESOURCE(IDI_MMSOGLWIN));
	wcex.hCursor		= LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground	= (HBRUSH)(COLOR_WINDOW+1);
	wcex.lpszMenuName	= MAKEINTRESOURCE(IDC_MMSOGLWIN);
	wcex.lpszClassName	= szWindowClass;
	wcex.hIconSm		= LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));
	return RegisterClassEx(&wcex);
}
/**
* InitInstance() - Everything for the application is initialized in this function.  We start by creating an OGL compatible window. 
Next we initialize DirectX using the hWnd for our OGL compatible window.
With DX initialized we then create our OpenGL context and grab function pointers for all the APIs we need to render our scene.
With GL initialized, we load up our vertex/fragment shaders and then create our open GL textures. 
The last thing we do is bind the OGL textures to our DirectX shared surfaces using NV_DX_Interop.  
This kind of approach is used because  DXVA  doesn't output to OpenGL textures directly. 
DirectX is also used to perform GP conversion from NV12 to ARGB color space as we reap video frames from VLC via the StretchRect function. 
Note that USESHADER defined in stdafx.h can be turned off if you want to avoid using vertex / fragement shaders during rendering.  Just comment it out.

* @param hInstance Handle to current application instance..
* @param nCmdShow How the window will be shown.
* @return Pass/Fail status.
*/
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
	HWND hWnd;
	hInst = hInstance;
	hWnd = CreateOpenGLWindow(szTitle, 0, 0, WINDOWWIDTH, WINDOWHEIGHT, PFD_TYPE_RGBA, 0, hInstance);
	if (!hWnd) {
		return FALSE;
	}
	HRESULT hr;	



    hDC = GetDC(hWnd);
    hRC = wglCreateContext(hDC);
	setupglfuncptrs();
#ifdef USESHADER
	createshaders();
#endif
	creatOGLtexture();

	//this is the input DX surface we use for getting decoded frame from VLC. YV12 is the natural hw format for DXVA decoder used by VLC
	/*testdx->CreateOffscreenPlainSurface(video_width, video_height,
		D3DFMT_YV12, VID); *///D3DFMT_NV12
	
	/*testdx->CreateOffscreenPlainSurface(video_width, video_height,
		 D3DFMT_NV12, //  //D3DFMT_UYVY, //this sufrace is not in use currently, it is just for testing
		(VID-1)	 ); */

	//currently MAXVIDEOCLIPS ==1, only one video is being displayed at a time but we keep the loop here for generic case and as a legacy :)
	for(int i = 0; i < MAXVIDEOCLIPS; i++) {
#ifdef DX_SCALE
		HANDLE  pSharedHandle = NULL; //important!
		int outtex_width = testdx->m_dwWidth; //output window client area Width
		int outtex_height = testdx->m_dwHeight;//output window client area Height
		//For the sake of perfomance: if an output  window size is smaller than an input video size use it, othrewise use an input video size as a texture size
		if ((testdx->m_dwWidth * testdx->m_dwHeight) > (video_width * video_height)){
			outtex_width = video_width; 
			outtex_height = video_height;
		}
			//here we use the WINDOWWIDTH in m_dwWidth, WINDOWHEIGHT in m_dwHeight as input texture size, not an original video size.
		// m_SharedTexture - is the IDirect3DTexture9* type, initialized by NULL proior to this function call, and we don't use it anywhere except for this function call
			hr = testdx->GetDevice()->CreateTexture(outtex_width, outtex_height, 1, D3DUSAGE_RENDERTARGET, D3DFMT_X8R8G8B8, D3DPOOL_DEFAULT, &testdx->m_SharedTexture, &testdx->m_hSharedSurfaceArray[i]);
			if (FAILED(hr)) return 0;
			hr = testdx->m_SharedTexture->GetSurfaceLevel(0, &testdx->m_pSharedSurfaceArray[i]);
			if (FAILED(hr)) return 0;
			hr = testdx->GetDevice()->SetRenderTarget(0, testdx->m_pSharedSurfaceArray[i]);
			if (FAILED(hr)) return 0;

		testdx->CreateShaderDXOffscreenPlainSurface(video_width, video_height, i); 
#endif
	}
	for(int i = 0; i < MAXVIDEOCLIPS; i++) {
//!!		bindtexture(testdx, m_h264TextureArray[i], m_hH264DeviceArray[i], m_hH264TextureArray[i], i); //Bind a DirectX surface to an OpenGL texture 
	}
	ShowWindow(hWnd, nCmdShow);
	UpdateWindow(hWnd);
	return TRUE;
}
/**
* WndProc() - Our windows message processing loop.  Used to deal with window resize, user input, and paint messages.
* @param hWnd Handle to the window that generated the message.
* @param message Actual message begin recieved.
* @param wParam Additional message info.
* @param lParam Additional message info.
* @return The return value is the result of the message processing and depends on the message sent.
*/
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	int wmId, wmEvent;
	PAINTSTRUCT ps;
	HDC hdc;

	switch (message) {
	case WM_COMMAND:
		wmId    = LOWORD(wParam);
		wmEvent = HIWORD(wParam);
		switch (wmId) {
		case IDM_ABOUT:
			DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
			break;
		case IDM_EXIT:
			unbindtexture();
			//cleanupdx();
			cleanupogl();
			wglMakeCurrent(NULL, NULL);
			ReleaseDC(hWnd,hDC);
			wglDeleteContext(hRC);
			DestroyWindow(hWnd);
			break;
		default:
			return DefWindowProc(hWnd, message, wParam, lParam);
		}
		break;
	case WM_PAINT:
		//if (bindtex)display();
		hdc = BeginPaint(hWnd, &ps);
		EndPaint(hWnd, &ps);
		break;
    case WM_SIZE:
		m_cx = LOWORD(lParam);
		m_cy = HIWORD(lParam);
		wglMakeCurrent(hDC, hRC);
		glViewport(0, 0, LOWORD(lParam), HIWORD(lParam));
		wglMakeCurrent(NULL, NULL);
		PostMessage(hWnd, WM_PAINT, 0, 0);
		break;
	case WM_DESTROY:
		//cleanupdx();
		cleanupogl();
		wglMakeCurrent(NULL, NULL);
		ReleaseDC(hWnd,hDC);
		wglDeleteContext(hRC);
		PostQuitMessage(0);
		break;
    case WM_MOUSEWHEEL:
            if((short) HIWORD(wParam)< 0) {
				nZoom = nZoom - 0.25f;
			}
			else {
				nZoom = nZoom + 0.25f;
			}
            break;
	case WM_KEYDOWN: 
		switch (wParam) { 
			case VK_LEFT: 
                xoffsetcurrent = xoffsetcurrent - offsetincrement;    
				break; 
			case VK_RIGHT: 
                xoffsetcurrent = xoffsetcurrent + offsetincrement;     
				break; 
			case VK_UP: 
                yoffsetcurrent = yoffsetcurrent - offsetincrement;     
				break; 
			case VK_DOWN: 
                yoffsetcurrent = yoffsetcurrent + offsetincrement;
				break; 
		}
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}
/**
* About() - This is an "about" box.  It has some instructions on how to use the app in it.
* @param hDlg Handle to the dialog box.
* @param message Message for this handler.
* @param wParam Additional message info..
* @param lParam Additional message info..
* @return The return value is the result of the message processing and depends on the message sent.
*/
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message) {
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;
	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) {
			EndDialog(hDlg, LOWORD(wParam));
			return (INT_PTR)TRUE;
		}
		break;
	}
	return (INT_PTR)FALSE;
}
/**
* CreateOpenGLWindow() - This function just creates an OpenGL compatible window and sets the pixel format.
* @param title Title of the window.
* @param x Coordinate position of the window on the screen.
* @param y Coordinate position of the window on the screen.
* @param width Width of the window.
* @param height height of the window.
* @return Handle to the new OpenGL window.
*/
HWND CreateOpenGLWindow(TCHAR* title, int x, int y, int width, int height, 
		   BYTE type, DWORD flags, HINSTANCE hInstance)
{
    int         pf;
    HDC         hDC;
    WNDCLASS    wc;

	hWnd = CreateWindow(szWindowClass, szTitle, WS_OVERLAPPEDWINDOW |
			WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
			x, y, width, height, NULL, NULL, hInstance, NULL);

    if (hWnd == NULL) {
	MessageBox(NULL, L"CreateWindow() failed:  Cannot create a window.", L"Error", MB_OK);
	return NULL;
    }
    hDC = GetDC(hWnd);
	static	PIXELFORMATDESCRIPTOR pfd=
    {
        sizeof(PIXELFORMATDESCRIPTOR),  1,                              
        PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,               
        PFD_TYPE_RGBA,                  
        32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0,                              
        PFD_MAIN_PLANE,                 
        0, 0, 0, 0                         
    };
    pf = ChoosePixelFormat(hDC, &pfd);
    if (pf == 0) {
	MessageBox(NULL, L"ChoosePixelFormat() failed:  Cannot find a suitable pixel format.", L"Error", MB_OK); 
	return 0;
    } 
    if (SetPixelFormat(hDC, pf, &pfd) == FALSE) {
	MessageBox(NULL, L"SetPixelFormat() failed:  Cannot set format specified.", L"Error", MB_OK);
	return 0;
    }
    DescribePixelFormat(hDC, pf, sizeof(PIXELFORMATDESCRIPTOR), &pfd);
    ReleaseDC(hWnd,hDC);
    return hWnd;
}
/**
* display() - This is our main OGL based rendering loop.  Before drawing anything using OpenGL we get the next video frame data converted from YV12 to ARGB by StretchRect call
It happens in cbVideoPostrender.
In this implementation display is being called independently on VLC loop in another thread without any sync so that if the next frame is not ready yet it will dispaly the previous one
(old texture will remain). 

The USESHADER define enables the use of vertex/fragment shaders during rendering.  This is on by default in this code. 
You can disable the shaders by commenting out USESHADER in stdafx.h if you need to. 
For our shader rendering path, we bind all of our video textures to our uniform shader variables, calculate for zoom/pan, and just draw a single quad.
The vertex shader / fragment shader handles the rest.  Without the shader, the code is a little less efficient. 
 Zoom / Pan do not work without the shader.  When we are done rendering our scene we unlock our shared surfaces using the NV_DX_Interop extension.
* @return None.
*/    
void display()
{
	//vz!!! return; 
	bool res;
	//!!!!!!!!!!!!!!!!!!we need to lock our shared surfaces using NV_DX_Interop before we being our OpenGL rendering.
	res = wglMakeCurrent(hDC, hRC);
#ifdef USESHADER	
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, m_cx, m_cy, 0, -1, 1);
    glDisable(GL_DEPTH_TEST);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
	glEnable(GL_TEXTURE_2D);
    glPushMatrix();
	glClearColor(1.0, 0, 1.0, 1.);
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glUseProgram (shadercombinedprogram);

	for(int i = 0; i < MAXVIDEOCLIPS; i++) { //remember MAXVIDEOCLIPS is equal to 1 and the loop is here for general case as a legacy
		res = wglDXLockObjectsNV(m_hH264DeviceArray[i], 1, &m_hH264TextureArray[i]);
	}

	for(int i = 0; i < MAXVIDEOCLIPS; i++) {
		glActiveTexture(GL_TEXTURE0 + i);
		glBindTexture(GL_TEXTURE_2D, m_h264TextureArray[i]);
		glUniform1i(testdtexArray[i],i);
	}

	glUniform1f(testxoffset, xoffsetcurrent);
	glUniform1f(testyoffset, yoffsetcurrent);
	glUniform1f(texcoordscalar,apptexcoordscalar);
	glUniform1f(xtexcoordmultiplier,appxtexcoordmultiplier);
	glUniform1f(ytexcoordmultiplier,appytexcoordmultiplier);
	glUniform1f(numvideos,appnumvideos);

	float box = nZoom;
	float aspect = 1.0f;
	float xval = box;
	float yval = box*aspect;
	glBegin(GL_QUADS);
	glTexCoord2d(1.0f, 1.0f); glVertex2f(-xval, -yval);
	glTexCoord2d(1.0f, 0.0f); glVertex2f(-xval, yval);
	glTexCoord2d(0.0f, 0.0f); glVertex2f(xval, yval);
	glTexCoord2d(0.0f, 1.0f); glVertex2f(xval, -yval); /**/
#else
	glViewport(0, 0, m_cx, m_cy);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, m_cx, m_cy, 0, -1, 1);
    glDisable(GL_DEPTH_TEST);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

	glEnable(GL_TEXTURE_2D);
    glPushMatrix();
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	for(int i = 0; i < MAXVIDEOCLIPS; i++) {
		glActiveTexture(GL_TEXTURE0 + i);
		glBindTexture(GL_TEXTURE_2D, m_h264TextureArray[i]);
	}

	glBegin(GL_QUADS);
	glTexCoord2d(0.0f, 0.0f); glVertex2f(0.0f, 0.0f);
	glTexCoord2d(0.0f, 1.0f); glVertex2f(0.0f, (GLfloat)unity);
	glTexCoord2d(1.0f, 1.0f); glVertex2f((GLfloat)unitx, (GLfloat)unity);
	glTexCoord2d(1.0f, 0.0f); glVertex2f((GLfloat)unitx, 0.0f);
	glEnd();
#endif
  glEnd();  /**/

	glPopMatrix();
	SwapBuffers(hDC);
   glFlush();	
   
   for (int i = 0; i < MAXVIDEOCLIPS; i++) {
		res = wglDXUnlockObjectsNV(m_hH264DeviceArray[i], 1, &m_hH264TextureArray[i]);
	}/**/



#if 0 //def DEBUG
	if (firstframe == 1){
		SaveAsBMP("c:\\temp\\ogl.bmp");
		firstframe++;
	}

	DWORD dwErr = glGetError();
	if (dwErr > 0){
		MessageBox(NULL, L"some rrrrror!", L"failed", MB_OK);
}
#endif
	res = wglMakeCurrent(NULL,NULL);
	//framecounter++;
}

/**
* setupglfuncptrs() - Grab function pointers to everything we need to write this application.  Including NV_DX_Interop functions.  
* @return None.
*/
void setupglfuncptrs()
{
	wglMakeCurrent(hDC, hRC);
	glGetUniformLocation = (PFNGLGETUNIFORMLOCATIONPROC)wglGetProcAddress("glGetUniformLocation");
	glCreateProgram = (PFNGLCREATEPROGRAMPROC)wglGetProcAddress("glCreateProgram");
	glUniform1i = (PFNGLUNIFORM1IPROC)wglGetProcAddress("glUniform1i");
	glDeleteProgram = (PFNGLDELETEPROGRAMPROC)wglGetProcAddress("glDeleteProgram");
	glUniform1iv = (PFNGLUNIFORM1IVPROC)wglGetProcAddress("glUniform1iv");
	glUseProgram = (PFNGLUSEPROGRAMPROC)wglGetProcAddress("glUseProgram");
	glUniform2iv = (PFNGLUNIFORM2IVPROC)wglGetProcAddress("glUniform2iv");
	glAttachShader = (PFNGLATTACHSHADERPROC)wglGetProcAddress("glAttachShader");
	glUniform3iv = (PFNGLUNIFORM3IVPROC)wglGetProcAddress("glUniform3iv");
	glDetachShader = (PFNGLDETACHSHADERPROC)wglGetProcAddress("glDetachShader");
	glUniform4iv = (PFNGLUNIFORM4IVPROC)wglGetProcAddress("glUniform4iv");
	glLinkProgram = (PFNGLLINKPROGRAMPROC)wglGetProcAddress("glLinkProgram");
	glUniform1f = (PFNGLUNIFORM1FPROC)wglGetProcAddress("glUniform1f");
	glGetProgramiv = (PFNGLGETPROGRAMIVPROC)wglGetProcAddress("glGetProgramiv");
	glUniform1fv = (PFNGLUNIFORM1FVPROC)wglGetProcAddress("glUniform1fv");
	glGetShaderInfoLog = (PFNGLGETSHADERINFOLOGPROC)wglGetProcAddress("glGetShaderInfoLog");
	glUniform2fv = (PFNGLUNIFORM2FVPROC)wglGetProcAddress("glUniform2fv");
	glGetAttribLocation = (PFNGLGETATTRIBLOCATIONPROC)wglGetProcAddress("glGetAttribLocation");
	glUniform3fv = (PFNGLUNIFORM3FVPROC)wglGetProcAddress("glUniform3fv");
	glUniformMatrix4fv = (PFNGLUNIFORMMATRIX4FVPROC)wglGetProcAddress("glUniformMatrix4fv");
	glVertexAttrib1f = (PFNGLVERTEXATTRIB1FPROC)wglGetProcAddress("glVertexAttrib1f");
	glVertexAttrib2fv = (PFNGLVERTEXATTRIB2FVPROC)wglGetProcAddress("glVertexAttrib2fv");
	glUniform4fv = (PFNGLUNIFORM4FVPROC)wglGetProcAddress("glUniform4fv");
	glEnableVertexAttribArray = (PFNGLENABLEVERTEXATTRIBARRAYPROC)wglGetProcAddress("glEnableVertexAttribArray");
	glVertexAttrib1fv = (PFNGLVERTEXATTRIB1FVPROC)wglGetProcAddress("glVertexAttrib1fv");
	glVertexAttrib4fv = (PFNGLVERTEXATTRIB4FVPROC)wglGetProcAddress("glVertexAttrib4fv");
	glBindAttribLocation = (PFNGLBINDATTRIBLOCATIONPROC)wglGetProcAddress("glBindAttribLocation");
	glActiveTexture = (PFNGLACTIVETEXTUREPROC)wglGetProcAddress("glActiveTexture");
	glVertexAttrib3fv = (PFNGLVERTEXATTRIB3FVPROC)wglGetProcAddress("glVertexAttrib3fv");
	glCreateShader = (PFNGLCREATESHADERPROC)wglGetProcAddress("glCreateShader");
	glShaderSource = (PFNGLSHADERSOURCEPROC)wglGetProcAddress("glShaderSource");
	glDeleteShader = (PFNGLDELETESHADERPROC)wglGetProcAddress("glDeleteShader");
	glGetShaderiv = (PFNGLGETSHADERIVPROC)wglGetProcAddress("glGetShaderiv");
	glCompileShader = (PFNGLCOMPILESHADERPROC)wglGetProcAddress("glCompileShader");
	glGenBuffers = (PFNGLGENBUFFERSPROC)wglGetProcAddress("glGenBuffers");
	glBufferData = (PFNGLBUFFERDATAPROC)wglGetProcAddress("glBufferData");
	glVertexAttribPointer = (PFNGLVERTEXATTRIBPOINTERPROC)wglGetProcAddress("glVertexAttribPointer");
	glBindBuffer = (PFNGLBINDBUFFERPROC)wglGetProcAddress("glBindBuffer");
	wglDXSetResourceShareHandleNV = (PFNWGLDXSETRESOURCESHAREHANDLENVPROC)wglGetProcAddress("wglDXSetResourceShareHandleNV");
	wglDXOpenDeviceNV = (PFNWGLDXOPENDEVICENVPROC)wglGetProcAddress("wglDXOpenDeviceNV");
	wglDXCloseDeviceNV = (PFNWGLDXCLOSEDEVICENVPROC)wglGetProcAddress("wglDXCloseDeviceNV");
	wglDXRegisterObjectNV = (PFNWGLDXREGISTEROBJECTNVPROC)wglGetProcAddress("wglDXRegisterObjectNV");
	wglDXUnregisterObjectNV = (PFNWGLDXUNREGISTEROBJECTNVPROC)wglGetProcAddress("wglDXUnregisterObjectNV");
	wglDXObjectAccessNV = (PFNWGLDXOBJECTACCESSNVPROC)wglGetProcAddress("wglDXObjectAccessNV");
	wglDXLockObjectsNV = (PFNWGLDXLOCKOBJECTSNVPROC)wglGetProcAddress("wglDXLockObjectsNV");
	wglDXUnlockObjectsNV = (PFNWGLDXUNLOCKOBJECTSNVPROC)wglGetProcAddress("wglDXUnlockObjectsNV");
	wglMakeCurrent(NULL,NULL);
}
/**
* cleanupogl() - Clean up after OpenGL.  Delete our textures, delete our shaders, delete the shader program.
* @return None.
*/
void cleanupogl() 
{
	wglMakeCurrent(hDC, hRC);
	if (m_bTextureInitialized) {
		for(int i = 0; i < MAXVIDEOCLIPS; i++) {
			glDeleteTextures(1, &m_h264TextureArray[i]);
		}
	}
	glDetachShader(shadercombinedprogram, glfragmentshader);
	glDetachShader(shadercombinedprogram, glvertexshader);
	glDeleteProgram(shadercombinedprogram);
	shadercombinedprogram = NULL;
	glfragmentshader = NULL;
	glvertexshader = NULL;
	wglMakeCurrent(NULL, NULL);
}
/**
* initDX() - Initializes DirectX using the hWnd for the OpenGL window.  Make the DirectX context the same width / height as the OpenGL context.
* @return None.

void initDX(int width, int height, HINSTANCE hInstance, HWND eHwnd)
{
	testdx = new SimpleDXDevice();
	testdx->CreateDevice(width,height,0,hInstance,eHwnd); //here we check CheckDeviceFormatConversion from YUV to RGBA
}*/


/**
* creatOGLtexture() - Create our OpenGL texture.  If the textures are alreaedy created, delete them and recreate.
*/
void creatOGLtexture(void)
{
	bool res = wglMakeCurrent(hDC, hRC);
	if (m_bTextureInitialized) {
		for(int i = 0; i < MAXVIDEOCLIPS; i++) {
			glDeleteTextures(1, &m_h264TextureArray[i]);
		}
	}
	for(int i = 0; i < MAXVIDEOCLIPS; i++) {
		glGenTextures(1, &m_h264TextureArray[i]);
		glBindTexture(GL_TEXTURE_2D, m_h264TextureArray[i]);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexImage2D(GL_TEXTURE_2D, 0,  GL_RGBA, m_cx, m_cy, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
	}
	m_bTextureInitialized = TRUE;
	wglMakeCurrent(NULL, NULL);
}
/**
* bindtexture() - Bind a DirectX surface to an OpenGL texture using the NV_DX_Interop extension.
* @param pSimpleDxDevice Poitner to our simple DirectX device class.  This class holds our DirectX handles to the shared surfaces.
* @param texture The OpenGL texture we want to bind to a DirectX texture using NV_DX_Interop.
* @param hDevice This value is returned by NV_DX_Interop.  Keep track of it.
* @param hTexture This value is returned by NV_DX_Interop.  Keep track of it.
* @return None. */


bool bindtextureVLC(IDirect3DDevice9* pDX9, LPDIRECT3DSURFACE9 dxSurf,HANDLE  dxHandle, GLuint texture, HANDLE& hDevice, HANDLE& hTexture)
{

	bool res = wglMakeCurrent(hDC, hRC);
	if (WGL_NV_DX_interop) {
		hDevice = NULL;
		hDevice = wglDXOpenDeviceNV(pDX9);
		if (hDevice) {
			BOOL success = wglDXSetResourceShareHandleNV(dxSurf,  dxHandle);
			hTexture = wglDXRegisterObjectNV(hDevice, dxSurf, texture, GL_TEXTURE_2D, WGL_ACCESS_READ_WRITE_NV);  //WGL_ACCESS_READ_ONLY_NV
			if (hTexture == NULL){
				DWORD dwErr = GetLastError();  
				if (dwErr == ERROR_OPEN_FAILED){
					dwErr = 888;
				}
				return false;
			}
		}
		else
			return false;
	}

	wglMakeCurrent(NULL, NULL);
	return true;
}

/**
* unbindtexture() - Unbinds all of the shared OpenGL/DirectX textures in this application using NV_DX_Interop.
* @return Pass/Fail status.
*/
bool unbindtexture()
{
	wglMakeCurrent(hDC, hRC);
	if (WGL_NV_DX_interop) {
		for(int i = 0; i < MAXVIDEOCLIPS; i++) {
			if (m_hH264TextureArray[i]) {
				wglDXUnregisterObjectNV(m_hH264DeviceArray[i], m_hH264TextureArray[i]);
				m_hH264TextureArray[i] = NULL;
			}
		}
	}
	wglMakeCurrent(NULL, NULL);
	return true;
}
/**
* createshaders() - Create our shaders, combine them into a program and then grab all of our uniform variables.
* @return Pass/Fail status.
*/
bool createshaders()
{
	wglMakeCurrent(hDC, hRC);
	glvertexshader = glCreateShader (GL_VERTEX_SHADER);
	glShaderSource (glvertexshader, 1, &vertexshaderstring, NULL);
	glCompileShader (glvertexshader);
	glfragmentshader = glCreateShader (GL_FRAGMENT_SHADER);
	glShaderSource (glfragmentshader, 1, &fragmentshaderstring, NULL);
	glCompileShader (glfragmentshader);
	shadercombinedprogram = glCreateProgram ();
	glAttachShader (shadercombinedprogram, glfragmentshader);
	glAttachShader (shadercombinedprogram, glvertexshader);
	glLinkProgram (shadercombinedprogram);
	char *texsampler = new char[256];
	for(int i = 0; i < MAXVIDEOCLIPS; i++) {
		printf(texsampler,"dtex[%d]",i);
		testdtexArray[i] = glGetUniformLocation( shadercombinedprogram, texsampler);
	}
	delete texsampler;
	testxoffset = glGetUniformLocation( shadercombinedprogram, "xoffset");
	testyoffset = glGetUniformLocation( shadercombinedprogram, "yoffset");
	texcoordscalar = glGetUniformLocation( shadercombinedprogram, "texcoordscalar");
	xtexcoordmultiplier = glGetUniformLocation( shadercombinedprogram, "xtexcoordmultiplier");
	ytexcoordmultiplier = glGetUniformLocation( shadercombinedprogram, "ytexcoordmultiplier");
	numvideos = glGetUniformLocation( shadercombinedprogram, "numvideos");
	return true;
}