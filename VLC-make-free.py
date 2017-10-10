#!/usr/bin/env python

import fnmatch
import os
import re


##### IMPORTANT
# These 3 lists should be synchonized with https://www.dropbox.com/s/v2jqpkpftrie87g/Clean%20VLC%20-%20win.xlsx?dl=0

# GPL
gplItems = [ 'libmad_plugin', 'libdca_plugin', 'access_realrtsp_plugin', 'dshow_plugin', 'dtv_plugin', 'dvdnav_plugin', 'dvdread_plugin', 'rtp_plugin', 'wasapi_plugin', 'dts_plugin', 'faad_plugin', 'mpeg2_plugin', 't140_plugin', 'x264_plugin', 'x265_plugin', 'gestures_plugin', 'hotkeys_plugin', 'oldrc_plugin', 'win_hotkeys_plugin', 'mpc_plugin', 'real_plugin', 'sid_plugin', 'qt4_plugin', 'skins2_plugin', 'lua_plugin', 'audioscrobbler_plugin', 'export_plugin', 'libfile_logger_plugin', 'liblogger_plugin', 'stats_plugin', 'vod_rtsp_plugin', 'podcast_plugin', 'sap_plugin', 'upnp_plugin', 'stream_out_duplicate_plugin', 'stream_out_rtp_plugin', 'stream_out_stats_plugin', 'atmo_plugin', 'deinterlace_plugin', 'hqdn3d_plugin', 'motionblur_plugin', 'motiondetect_plugin', 'postproc_plugin', 'remoteosd_plugin', 'rotate_plugin', 'glspectrum_plugin', 'goom_plugin', 'projectm_plugin', 'visual_plugin' ]

# Licensed
licensedItems = [ 'bluray-j2se-0.9.2.jar', 'bluray_plugin', 'a52_plugin', 'aes3_plugin', 'cc_plugin', 'cdg_plugin', 'crystalhd_plugin', 'cvdsub_plugin', 'ddummy_plugin', 'dmo_plugin', 'dvbsub_plugin', 'g711_plugin', 'kate_plugin', 'ass_plugin', 'lpcm_plugin', 'mft_plugin', 'mpeg_audio_plugin', 'quicktime_plugin', 'scte27_plugin', 'speex_plugin', 'spudec_plugin', 'stl_plugin', 'subsdec_plugin', 'svcdsub_plugin' ]

# Useless
uselessItems = [ 'direct3d11', 'cdda_plugin', 'idummy_plugin', 'rar_plugin', 'screen_plugin', 'sdp_plugin', 'shm_plugin', 'vcd_plugin', 'vdr_plugin', 'zip_plugin', 'access_output_dummy_plugin', 'access_output_file_plugin', 'access_output_http_plugin', 'access_output_livehttp_plugin', 'access_output_shout_plugin', 'access_output_udp_plugin', 'adummy_plugin', 'afile_plugin', 'amem_plugin', 'mmdevice_plugin', 'waveout_plugin', 'edummy_plugin', 'jpeg_plugin', 'png_plugin', 'substx3g_plugin', 'subsusf_plugin', 'uleaddvaudio_plugin', 'zvbi_plugin', 'dummy_plugin', 'netsync_plugin', 'ntservice_plugin', 'win_msg_plugin', 'mux_asf_plugin', 'mux_avi_plugin', 'mux_dummy_plugin', 'mux_mp4_plugin', 'mux_mpjpeg_plugin', 'mux_ogg_plugin', 'mux_ps_plugin', 'mux_ts_plugin', 'mux_wav_plugin', 'record_plugin', 'stream_out_autodel_plugin', 'stream_out_bridge_plugin', 'stream_out_chromaprint_plugin', 'stream_out_delay_plugin', 'stream_out_description_plugin', 'stream_out_display_plugin', 'stream_out_dummy_plugin', 'stream_out_es_plugin', 'stream_out_gather_plugin', 'stream_out_langfromtelx_plugin', 'stream_out_mosaic_bridge_plugin', 'stream_out_raop_plugin', 'stream_out_record_plugin', 'stream_out_setid_plugin', 'stream_out_smem_plugin', 'stream_out_standard_plugin', 'stream_out_transcode_plugin', 'freetype_plugin', 'tdummy_plugin', 'caca_plugin', 'direct2d_plugin', 'direct3d_plugin', 'directdraw_plugin', 'drawable_plugin', 'glwin32_plugin', 'gl_plugin', 'vdummy_plugin', 'wingdi_plugin', 'yuv_plugin', 'clone_plugin', 'panoramix_plugin', 'wall_plugin' ]

##### /IMPORTANT

# Other / not sync with the sheet
otherItems = [ 'direct3d11' ]

# Modules to remove)
items2clean = gplItems + licensedItems + uselessItems + otherItems

print( items2clean )

plugins = []

# Windows # find all dlls
for root, dirnames, filenames in os.walk('.'):
  for filename in fnmatch.filter(filenames, '*.dll'):
    plugins.append(os.path.join(root, filename))

# Mac OS X # find all dylib
for root, dirnames, filenames in os.walk('.'):
  for filename in fnmatch.filter(filenames, '*.dylib'):
    plugins.append(os.path.join(root, filename))

# Linux # find all .so
for root, dirnames, filenames in os.walk('.'):
  for filename in fnmatch.filter(filenames, '*.so'):
    plugins.append(os.path.join(root, filename))

# create the list to clean
plugins_to_delete = []

for plugin in plugins:
  for item in items2clean:
    se = re.search( item, plugin, re.M|re.I )
    if se:
      plugins_to_delete.append( plugin )

print( 'plugins list to clean: ' )
print( plugins_to_delete )

# do the cleaning
for plugin in plugins_to_delete:
  try:
    os.remove(plugin)
  except OSError:
    pass
