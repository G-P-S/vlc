/*****************************************************************************
 * playlist.c :  Playlist import module
 *****************************************************************************
 * Copyright (C) 2004 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Clément Stenac <zorglub@videolan.org>
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
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <vlc_common.h>
#include <vlc_plugin.h>
#include <vlc_demux.h>
#include <vlc_url.h>

#if defined( _WIN32 ) || defined( __OS2__ )
# include <ctype.h>                          /* isalpha */
#endif
#include <assert.h>

#include "playlist.h"

/*****************************************************************************
 * Module descriptor
 *****************************************************************************/
#define SHOW_ADULT_TEXT N_( "Show shoutcast adult content" )
#define SHOW_ADULT_LONGTEXT N_( "Show NC17 rated video streams when " \
                "using shoutcast video playlists." )

#define SKIP_ADS_TEXT N_( "Skip ads" )
#define SKIP_ADS_LONGTEXT N_( "Use playlist options usually used to prevent " \
    "ads skipping to detect ads and prevent adding them to the playlist." )

vlc_module_begin ()
    add_shortcut( "playlist" )
    set_category( CAT_INPUT )
    set_subcategory( SUBCAT_INPUT_DEMUX )

    add_obsolete_integer( "parent-item" ) /* removed since 1.1.0 */

    add_bool( "playlist-skip-ads", true,
              SKIP_ADS_TEXT, SKIP_ADS_LONGTEXT, false )

    set_shortname( N_("Playlist") )
    set_description( N_("Playlist") )
    add_submodule ()
        set_description( N_("M3U playlist import") )
        add_shortcut( "playlist", "m3u", "m3u8", "m3u-open" )
        set_capability( "demux", 10 )
        set_callbacks( Import_M3U, Close_M3U )
    add_submodule ()
        set_description( N_("RAM playlist import") )
        add_shortcut( "playlist", "ram-open" )
        set_capability( "demux", 10 )
        set_callbacks( Import_RAM, NULL )
    add_submodule ()
        set_description( N_("PLS playlist import") )
        add_shortcut( "playlist", "pls-open" )
        set_capability( "demux", 10 )
        set_callbacks( Import_PLS, NULL )
    add_submodule ()
        set_description( N_("B4S playlist import") )
        add_shortcut( "playlist", "b4s-open", "shout-b4s" )
        set_capability( "demux", 10 )
        set_callbacks( Import_B4S, NULL )
    add_submodule ()
        set_description( N_("DVB playlist import") )
        add_shortcut( "playlist", "dvb-open" )
        set_capability( "demux", 10 )
        set_callbacks( Import_DVB, NULL )
    add_submodule ()
        set_description( N_("Podcast parser") )
        add_shortcut( "playlist", "podcast" )
        set_capability( "demux", 10 )
        set_callbacks( Import_podcast, NULL )
    add_submodule ()
        set_description( N_("XSPF playlist import") )
        add_shortcut( "playlist", "xspf-open" )
        set_capability( "demux", 10 )
        set_callbacks( Import_xspf, Close_xspf )
    add_submodule ()
        set_description( N_("New winamp 5.2 shoutcast import") )
        add_shortcut( "playlist", "shout-winamp" )
        set_capability( "demux", 10 )
        set_callbacks( Import_Shoutcast, NULL )
        add_bool( "shoutcast-show-adult", false,
                   SHOW_ADULT_TEXT, SHOW_ADULT_LONGTEXT, false )
    add_submodule ()
        set_description( N_("ASX playlist import") )
        add_shortcut( "playlist", "asx-open" )
        set_capability( "demux", 10 )
        set_callbacks( Import_ASX, NULL )
    add_submodule ()
        set_description( N_("Kasenna MediaBase parser") )
        add_shortcut( "playlist", "sgimb" )
        set_capability( "demux", 10 )
        set_callbacks( Import_SGIMB, Close_SGIMB )
    add_submodule ()
        set_description( N_("QuickTime Media Link importer") )
        add_shortcut( "playlist", "qtl" )
        set_capability( "demux", 10 )
        set_callbacks( Import_QTL, NULL )
    add_submodule ()
        set_description( N_("Google Video Playlist importer") )
        add_shortcut( "playlist", "gvp" )
        set_capability( "demux", 10 )
        set_callbacks( Import_GVP, NULL )
    add_submodule ()
        set_description( N_("Dummy IFO demux") )
        add_shortcut( "playlist" )
        set_capability( "demux", 12 )
        set_callbacks( Import_IFO, NULL )
    add_submodule ()
        set_description( N_("iTunes Music Library importer") )
        add_shortcut( "playlist", "itml" )
        set_capability( "demux", 10 )
        set_callbacks( Import_iTML, Close_iTML )
    add_submodule ()
        set_description( N_("WPL playlist import") )
        add_shortcut( "playlist", "wpl" )
        set_capability( "demux", 10 )
        set_callbacks( Import_WPL, Close_WPL )
vlc_module_end ()

int Control(demux_t *demux, int query, va_list args)
{
    (void) demux;
    switch( query )
    {
        case DEMUX_IS_PLAYLIST:
        {
            bool *pb_bool = va_arg( args, bool * );
            *pb_bool = true;
            return VLC_SUCCESS;
        }
        case DEMUX_GET_META:
        {
            return vlc_stream_vaControl(demux->s, STREAM_GET_META, args);
        }
        case DEMUX_HAS_UNSUPPORTED_META:
        {
            *(va_arg( args, bool * )) = false;
            return VLC_SUCCESS;
        }
    }
    return VLC_EGENERIC;
}

/**
 * Computes the base URL.
 *
 * Rebuilds the base URL for the playlist.
 */
char *FindPrefix(demux_t *p_demux)
{
    char *url;

    if (unlikely(asprintf(&url, "%s://%s", p_demux->psz_access,
                          p_demux->psz_location) == -1))
        url = NULL;
    return url;
}

/**
 * Resolves a playlist location.
 *
 * Resolves a resource location within the playlist relative to the playlist
 * base URL.
 */
char *ProcessMRL(const char *str, const char *base)
{
    char const* orig = str;

    if (str == NULL)
        return NULL;

#if (DIR_SEP_CHAR == '\\')
    /* UNC path prefix? */
    if (strncmp(str, "\\\\", 2) == 0
    /* Drive letter prefix? */
     || (isalpha((unsigned char)str[0]) && str[1] == ':'))
        /* Assume this an absolute file path - usually true */
        return vlc_path2uri(str, NULL);
    /* TODO: drive-relative path: if (str[0] == '\\') */
#endif

    /* The base URL is always an URL: it is the URL of the playlist.
     *
     * However it is not always known if the input string is a valid URL, a
     * broken URL or a local file path. As a rule, if it looks like a valid
     * URL, it must be treated as such, since most playlist formats use URLs.
     *
     * There are a few corner cases file paths that look like an URL but whose
     * URL representation does not match, notably when they contain a
     * percentage sign, a colon, a hash or a question mark. Luckily, they are
     * rather exceptional (and can be encoded as URL to make the playlist
     * work properly).
     *
     * If the input is not a valid URL, then we try to fix it up. It works in
     * all cases for URLs with incorrectly encoded segments, such as URLs with
     * white spaces or non-ASCII Unicode code points. It also works in most
     * cases where the input is a Unix-style file path, but not all.
     * It fails miserably if the playlist character encoding is misdetected.
     */
    char *rel = vlc_uri_fixup(str);
    if (rel != NULL)
        str = rel;

    char *abs = vlc_uri_resolve(base, str);
    free(rel);

    if (abs == NULL)
    {
        /** If the input is not a valid URL, see if there is a scheme:// where
         * the scheme itself consists solely of valid scheme-characters
         * (including the VLC's scheme-extension). If it does, fall back to
         * allowing the URI in order to not break back-compatibility.
         */
        char const* scheme_end = strstr( orig, "://" );
        char const* valid_chars = "abcdefghijklmnopqrstuvwxyz"
                                  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                  "0123456789" "+-./";
        if (scheme_end &&
            strspn (orig, valid_chars) == (size_t)(scheme_end - orig))
        {
            abs = strdup (orig);
        }
    }

    return abs;
}
