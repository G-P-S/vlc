/*
Copyright 2016 Intel Corporation All Rights Reserved.

The source code, information and material ("Material") contained herein is owned by Intel Corporation or 
its suppliers or licensors, and title to such Material remains with Intel Corporation or its suppliers or 
licensors. The Material contains proprietary information of Intel or its suppliers and licensors. The Material 
is protected by worldwide copyright laws and treaty provisions. No part of the Material may be used, copied, 
reproduced, modified, published, uploaded, posted, transmitted, distributed or disclosed in any way without 
Intel's prior express written permission. No license under any patent, copyright or other intellectual property 
rights in the Material is granted to or conferred upon you, either expressly, by implication, inducement, 
estoppel or otherwise. Any license under such intellectual property rights must be express and approved 
by Intel in writing.

Unless otherwise agreed by Intel in writing, you may not remove or alter this notice or any other notice embedded 
in Materials by Intel or Intel’s suppliers or licensors in any way.”
*/
#pragma once

#include "resource.h"
#include <SDKDDKVer.h>

#include <d3d9.h>
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>


#define WINDOWWIDTH 1920  // 640  //
#define WINDOWHEIGHT 960  //320 //
#define MAX_LOADSTRING 100
#define MAXPOSSIBLEVIDEOS 6
#define MAXVIDEOCLIPS 1
#define NUMVIDEOROW 1
#define NUMVIDEOCOL 1
#define USESHADER  1
#define FPS_RESOLUTION 1000

#define VID 5
#define NUMPLANES 6


ATOM MyRegisterClass(HINSTANCE hInstance);

struct sInputParams
{
	void* externallycreatedd3d9deviceptr;
	void* externallycreatedd3d9context;
	void* externallycreatedd3d9pp;
	void* externallycreatedhwnd;
	//sWindowParams externallycreatedsparams;
};

BOOL InitInstance(HINSTANCE, int);
int mainVLC(int argc, char **argv);

//from VLC
struct picture_sys_t
{
	LPDIRECT3DSURFACE9 surface;
	HANDLE pSharedHandle;
};

void display();
int  _tWinMain_(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPTSTR lpCmdLine, _In_ int nCmdShow);