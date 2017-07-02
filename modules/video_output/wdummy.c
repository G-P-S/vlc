/**
 * @file drawable.c
 * @brief Legacy monolithic LibVLC video window provider
 */
/*****************************************************************************
 * Copyright © 2017 VLC authors and VideoLAN
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
# include <config.h>
#endif

#include <stdarg.h>
#include <assert.h>

#include <vlc_common.h>
#include <vlc_plugin.h>
#include <vlc_vout_window.h>

static int  Open (vout_window_t *, const vout_window_cfg_t *);
static void Close(vout_window_t *);

/*
 * Module descriptor
 */
vlc_module_begin ()
    set_shortname (N_("Wdummy"))
    set_description (N_("Dummy vout window"))
    set_category (CAT_VIDEO)
    set_subcategory (SUBCAT_VIDEO_VOUT)
    set_capability ("vout window", 0)
    set_callbacks (Open, Close)
vlc_module_end ()

static int Control (vout_window_t *, int, va_list);



/**
 * Find the drawable set by libvlc application.
 */
static int Open (vout_window_t *wnd, const vout_window_cfg_t *cfg)
{
    VLC_UNUSED(cfg);

    wnd->control = Control;

    return VLC_SUCCESS;
}

/**
 * Release the drawable.
 */
static void Close (vout_window_t *wnd)
{
    VLC_UNUSED(wnd);
}


static int Control (vout_window_t *wnd, int query, va_list ap)
{
    VLC_UNUSED(ap);
    VLC_UNUSED(wnd);

    msg_Warn(wnd, "unsupported control query %d", query);
    return VLC_EGENERIC;
}
