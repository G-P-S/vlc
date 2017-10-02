#!/usr/bin/env python

import fnmatch
import os
import os.path
import re
import shutil

# GPL
gplItems_plugin = [ 'access_realrtsp_plugin', 'dshow_plugin', 'dtv_plugin', 'dvdnav_plugin', 'dvdread_plugin', 'rtp_plugin', 'wasapi_plugin', 'dts_plugin', 'faad_plugin', 'mpeg2_plugin', 't140_plugin', 'x264_plugin', 'x265_plugin', 'gestures_plugin', 'hotkeys_plugin', 'oldrc_plugin', 'win_hotkeys_plugin', 'mpc_plugin', 'real_plugin', 'sid_plugin', 'qt4_plugin', 'skins2_plugin', 'lua_plugin', 'audioscrobbler_plugin', 'export_plugin', 'logger_plugin', 'stats_plugin', 'vod_rtsp_plugin', 'podcast_plugin', 'sap_plugin', 'upnp_plugin', 'stream_out_duplicate_plugin', 'stream_out_rtp_plugin', 'stream_out_stats_plugin', 'atmo_plugin', 'deinterlace_plugin', 'hqdn3d_plugin', 'motionblur_plugin', 'motiondetect_plugin', 'postproc_plugin', 'remoteosd_plugin', 'rotate_plugin', 'glspectrum_plugin', 'goom_plugin', 'projectm_plugin', 'visual_plugin' ]
gplItems = [ 'access_realrtsp', 'dshow', 'dtv', 'dvdnav', 'dvdread', 'rtp', 'wasapi', 'dts', 'faad', 'mpeg2', 't140', 'x264', 'x265', 'gestures', 'hotkeys', 'oldrc', 'win_hotkeys', 'mpc', 'real', 'sid', 'qt4', 'skins2', 'lua', 'audioscrobbler', 'export', 'logger', 'stats', 'vod_rtsp', 'podcast', 'sap', 'upnp', 'stream_out_duplicate', 'stream_out_rtp', 'stream_out_stats', 'atmo', 'deinterlace', 'hqdn3d', 'motionblur', 'motiondetect', 'postproc', 'remoteosd', 'rotate', 'glspectrum', 'goom', 'projectm', 'visual' ]

# Licensed
licensedItems_plugin = [ 'bluray-j2se-0.9.2.jar', 'bluray_plugin', 'a52_plugin', 'aes3_plugin', 'cc_plugin', 'cdg_plugin', 'crystalhd_plugin', 'cvdsub_plugin', 'ddummy_plugin', 'dmo_plugin', 'dvbsub_plugin', 'g711_plugin', 'kate_plugin', 'ass_plugin', 'lpcm_plugin', 'mft_plugin', 'mpeg_audio_plugin', 'quicktime_plugin', 'scte27_plugin', 'speex_plugin', 'spudec_plugin', 'stl_plugin', 'subsdec_plugin', 'svcdsub_plugin' ]
licensedItems = [ 'bluray-j2se-0.9.2.jar', 'bluray', 'a52', 'aes3', 'cc', 'cdg', 'crystalhd', 'cvdsub', 'ddummy', 'dmo', 'dvbsub', 'g711', 'kate', 'ass', 'lpcm', 'mft', 'mpeg_audio', 'quicktime', 'scte27', 'speex', 'spudec', 'stl', 'subsdec', 'svcdsub' ]

# Useless
uselessItems_plugin = [ 'direct3d11', 'cdda_plugin', 'idummy_plugin', 'rar_plugin', 'screen_plugin', 'sdp_plugin', 'shm_plugin', 'vcd_plugin', 'vdr_plugin', 'zip_plugin', 'access_output_dummy_plugin', 'access_output_file_plugin', 'access_output_http_plugin', 'access_output_livehttp_plugin', 'access_output_shout_plugin', 'access_output_udp_plugin', 'a52tofloat32_plugin', 'a52tospdif_plugin', 'audiobargraph_a_plugin', 'chorus_flanger_plugin', 'compressor_plugin', 'dolby_surround_decoder_plugin', 'dtstofloat32_plugin', 'dtstospdif_plugin', 'equalizer_plugin', 'gain_plugin', 'headphone_channel_mixer_plugin', 'karaoke_plugin', 'mono_plugin', 'mpgatofixed32_plugin', 'normvol_plugin', 'param_eq_plugin', 'remap_plugin', 'samplerate_plugin', 'scaletempo_plugin', 'simple_channel_mixer_plugin', 'spatializer_plugin', 'speex_resampler_plugin', 'stereo_widen_plugin', 'trivial_channel_mixer_plugin', 'ugly_resampler_plugin', 'adummy_plugin', 'afile_plugin', 'amem_plugin', 'mmdevice_plugin', 'waveout_plugin', 'edummy_plugin', 'jpeg_plugin', 'png_plugin', 'substx3g_plugin', 'subsusf_plugin', 'uleaddvaudio_plugin', 'zvbi_plugin', 'dummy_plugin', 'netsync_plugin', 'ntservice_plugin', 'win_msg_plugin', 'mux_asf_plugin', 'mux_avi_plugin', 'mux_dummy_plugin', 'mux_mp4_plugin', 'mux_mpjpeg_plugin', 'mux_ogg_plugin', 'mux_ps_plugin', 'mux_ts_plugin', 'mux_wav_plugin', 'record_plugin', 'stream_out_autodel_plugin', 'stream_out_bridge_plugin', 'stream_out_chromaprint_plugin', 'stream_out_delay_plugin', 'stream_out_description_plugin', 'stream_out_display_plugin', 'stream_out_dummy_plugin', 'stream_out_es_plugin', 'stream_out_gather_plugin', 'stream_out_langfromtelx_plugin', 'stream_out_mosaic_bridge_plugin', 'stream_out_raop_plugin', 'stream_out_record_plugin', 'stream_out_setid_plugin', 'stream_out_smem_plugin', 'stream_out_standard_plugin', 'stream_out_transcode_plugin', 'freetype_plugin', 'tdummy_plugin', 'caca_plugin', 'direct2d_plugin', 'direct3d_plugin', 'directdraw_plugin', 'drawable_plugin', 'glwin32_plugin', 'gl_plugin', 'vdummy_plugin', 'wingdi_plugin', 'yuv_plugin', 'clone_plugin', 'panoramix_plugin', 'wall_plugin' ]
uselessItems = [ 'direct3d11', 'cdda', 'idummy', 'rar', 'screen', 'sdp', 'shm', 'vcd', 'vdr', 'zip', 'access_output_dummy', 'access_output_file', 'access_output_http', 'access_output_livehttp', 'access_output_shout', 'access_output_udp', 'a52tofloat32', 'a52tospdif', 'audiobargraph_a', 'chorus_flanger', 'compressor', 'dolby_surround_decoder', 'dtstofloat32', 'dtstospdif', 'equalizer', 'gain', 'headphone_channel_mixer', 'karaoke', 'mono', 'mpgatofixed32', 'normvol', 'param_eq', 'remap', 'samplerate', 'scaletempo', 'simple_channel_mixer', 'spatializer', 'speex_resampler', 'stereo_widen', 'trivial_channel_mixer', 'ugly_resampler', 'adummy', 'afile', 'amem', 'mmdevice', 'waveout', 'edummy', 'jpeg', 'png', 'substx3g', 'subsusf', 'uleaddvaudio', 'zvbi', 'dummy', 'netsync', 'ntservice', 'win_msg', 'mux_asf', 'mux_avi', 'mux_dummy', 'mux_mp4', 'mux_mpjpeg', 'mux_ogg', 'mux_ps', 'mux_ts', 'mux_wav', 'record', 'stream_out_autodel', 'stream_out_bridge', 'stream_out_chromaprint', 'stream_out_delay', 'stream_out_description', 'stream_out_display', 'stream_out_dummy', 'stream_out_es', 'stream_out_gather', 'stream_out_langfromtelx', 'stream_out_mosaic_bridge', 'stream_out_raop', 'stream_out_record', 'stream_out_setid', 'stream_out_smem', 'stream_out_standard', 'stream_out_transcode', 'freetype', 'tdummy', 'caca', 'direct2d', 'direct3d', 'directdraw', 'drawable', 'glwin32', 'gl', 'vdummy', 'wingdi', 'yuv', 'clone', 'panoramix', 'wall' ]

# Modules to remove)
items2clean = gplItems_plugin + licensedItems_plugin + uselessItems_plugin

items2clean_dir = gplItems + licensedItems + uselessItems

print( 'items2clean')
print( items2clean_dir )

plugins = []
plugins_dir = []

# Windows # find all dlls
for root, dirnames, filenames in os.walk('.'):
  for filename in fnmatch.filter(filenames, '*.dll'):
    plugins.append(os.path.join(root, filename))

# projects .
for root, dirnames, filenames in os.walk('.'):
#   if dirnames != []:
#plugins_dir.append(os.path.join(root, str(dirnames)))
#	  plugins_dir.extend(dirnames)
   for dirname in dirnames:
     path = os.path.join(root,dirname)
     print(path)
     plugins_dir.append(path)
print( 'plugins list found: ' )
#plugins_dir_flattened = [val for sublist in plugins_dir for val in sublist]
print( plugins_dir)


# create the list to clean
plugins_dir_to_delete = []
se = 0

for plugin in plugins_dir:
  for item in items2clean_dir:
    namefromd = os.path.basename(plugin)
#    print('plugin')
#    print(plugin)
#    print('namefromd')	
#    print(namefromd)
#    se = re.search( item, str(plugin), re.M|re.I )
    if namefromd == item:
	  plugins_dir_to_delete.append( plugin )

print( 'plugins list to clean: ' )
print( plugins_dir_to_delete )

# do the cleaning
#for plugin in plugins_dir_to_delete:
#  path = os.path.dirname('/'+plugin)
#  print(plugin)
#   try:
#     shutil.rmtree(path)
#   except OSError:
#     pass
for plugin in plugins_dir_to_delete:
   for root, dirs, files in os.walk(plugin):
       for name in files:
          os.remove(os.path.join(root, name))
   shutil.rmtree(plugin)
