/*****************************************************************************
 * ControlsBar.m: MacOS X interface module
 *****************************************************************************
 * Copyright (C) 2012-2016 VLC authors and VideoLAN
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne -at- videolan -dot- org>
 *          David Fuhrmann <david dot fuhrmann at googlemail dot com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#import "VLCControlsBarCommon.h"
#import "VLCMainWindowControlsBar.h"
#import "VLCMain.h"
#import "VLCCoreInteraction.h"
#import "VLCMainMenu.h"
#import "VLCPlaylist.h"
#import "CompatibilityFixes.h"

/*****************************************************************************
 * VLCMainWindowControlsBar
 *
 *  Holds all specific outlets, actions and code for the main window controls bar.
 *****************************************************************************/

@interface VLCMainWindowControlsBar()
{
    NSImage * _repeatImage;
    NSImage * _pressedRepeatImage;
    NSImage * _repeatAllImage;
    NSImage * _pressedRepeatAllImage;
    NSImage * _repeatOneImage;
    NSImage * _pressedRepeatOneImage;
    NSImage * _shuffleImage;
    NSImage * _pressedShuffleImage;
    NSImage * _shuffleOnImage;
    NSImage * _pressedShuffleOnImage;

    BOOL b_show_jump_buttons;
    BOOL b_show_playmode_buttons;

    NSLayoutConstraint *_hidePrevButtonConstraint;
    NSLayoutConstraint *_hideNextButtonConstraint;

    NSLayoutConstraint *_hideEffectsButtonConstraint;

    NSLayoutConstraint *_hideRepeatButtonConstraint;
    NSLayoutConstraint *_hideShuffleButtonConstraint;
}

- (void)addJumpButtons:(BOOL)b_fast;
- (void)removeJumpButtons:(BOOL)b_fast;
- (void)addPlaymodeButtons:(BOOL)b_fast;
- (void)removePlaymodeButtons:(BOOL)b_fast;

@end

@implementation VLCMainWindowControlsBar

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.stopButton setToolTip: _NS("Stop")];
    [[self.stopButton cell] accessibilitySetOverrideValue:_NS("Click to stop playback.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.stopButton cell] accessibilitySetOverrideValue:[self.stopButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    [self.playlistButton setToolTip: _NS("Show/Hide Playlist")];
    [[self.playlistButton cell] accessibilitySetOverrideValue:_NS("Click to switch between video output and playlist. If no video is shown in the main window, this allows you to hide the playlist.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.playlistButton cell] accessibilitySetOverrideValue:[self.playlistButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    [self.repeatButton setToolTip: _NS("Repeat")];
    [[self.repeatButton cell] accessibilitySetOverrideValue:_NS("Click to change repeat mode. There are 3 states: repeat one, repeat all and off.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.repeatButton cell] accessibilitySetOverrideValue:[self.repeatButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    [self.shuffleButton setToolTip: _NS("Shuffle")];
    [[self.shuffleButton cell] accessibilitySetOverrideValue:[self.shuffleButton toolTip] forAttribute:NSAccessibilityTitleAttribute];
    [[self.shuffleButton cell] accessibilitySetOverrideValue:_NS("Click to enable or disable random playback.") forAttribute:NSAccessibilityDescriptionAttribute];

    NSString *volumeTooltip = [NSString stringWithFormat:_NS("Volume: %i %%"), 100];
    [self.volumeSlider setToolTip: volumeTooltip];
    [[self.volumeSlider cell] accessibilitySetOverrideValue:_NS("Click and move the mouse while keeping the button pressed to use this slider to change the volume.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.volumeSlider cell] accessibilitySetOverrideValue:[self.volumeSlider toolTip] forAttribute:NSAccessibilityTitleAttribute];
    [self.volumeDownButton setToolTip: _NS("Mute")];
    [[self.volumeDownButton cell] accessibilitySetOverrideValue:_NS("Click to mute or unmute the audio.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.volumeDownButton cell] accessibilitySetOverrideValue:[self.volumeDownButton toolTip] forAttribute:NSAccessibilityTitleAttribute];
    [self.volumeUpButton setToolTip: _NS("Full Volume")];
    [[self.volumeUpButton cell] accessibilitySetOverrideValue:_NS("Click to play the audio at maximum volume.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.volumeUpButton cell] accessibilitySetOverrideValue:[self.volumeUpButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    [self.effectsButton setToolTip: _NS("Audio Effects")];
    [[self.effectsButton cell] accessibilitySetOverrideValue:_NS("Click to show an Audio Effects panel featuring an equalizer and further filters.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.effectsButton cell] accessibilitySetOverrideValue:[self.effectsButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    [self.prevButton setToolTip: _NS("Previous")];
    [[self.prevButton cell] accessibilitySetOverrideValue:_NS("Click to go to the previous playlist item.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.prevButton cell] accessibilitySetOverrideValue:[self.prevButton toolTip] forAttribute:NSAccessibilityTitleAttribute];
    [self.nextButton setToolTip: _NS("Next")];
    [[self.nextButton cell] accessibilitySetOverrideValue:_NS("Click to go to the next playlist item.") forAttribute:NSAccessibilityDescriptionAttribute];
    [[self.nextButton cell] accessibilitySetOverrideValue:[self.nextButton toolTip] forAttribute:NSAccessibilityTitleAttribute];

    if (!self.darkInterface) {
        [self.stopButton setImage: imageFromRes(@"stop")];
        [self.stopButton setAlternateImage: imageFromRes(@"stop-pressed")];

        [self.playlistButton setImage: imageFromRes(@"playlist-btn")];
        [self.playlistButton setAlternateImage: imageFromRes(@"playlist-btn-pressed")];
        _repeatImage = imageFromRes(@"repeat");
        _pressedRepeatImage = imageFromRes(@"repeat-pressed");
        _repeatAllImage  = imageFromRes(@"repeat-all");
        _pressedRepeatAllImage = imageFromRes(@"repeat-all-pressed");
        _repeatOneImage = imageFromRes(@"repeat-one");
        _pressedRepeatOneImage = imageFromRes(@"repeat-one-pressed");
        _shuffleImage = imageFromRes(@"shuffle");
        _pressedShuffleImage = imageFromRes(@"shuffle-pressed");
        _shuffleOnImage = imageFromRes(@"shuffle-blue");
        _pressedShuffleOnImage = imageFromRes(@"shuffle-blue-pressed");

        [self.volumeDownButton setImage: imageFromRes(@"volume-low")];
        [self.volumeTrackImageView setImage: imageFromRes(@"volume-slider-track")];
        [self.volumeUpButton setImage: imageFromRes(@"volume-high")];
        [self.volumeSlider setUsesBrightArtwork: YES];

        if (self.nativeFullscreenMode) {
            [self.effectsButton setImage: imageFromRes(@"effects-one-button")];
            [self.effectsButton setAlternateImage: imageFromRes(@"effects-one-button-pressed")];
        } else {
            [self.effectsButton setImage: imageFromRes(@"effects-double-buttons")];
            [self.effectsButton setAlternateImage: imageFromRes(@"effects-double-buttons-pressed")];
        }

        [self.fullscreenButton setImage: imageFromRes(@"fullscreen-double-buttons")];
        [self.fullscreenButton setAlternateImage: imageFromRes(@"fullscreen-double-buttons-pressed")];

        [self.prevButton setImage: imageFromRes(@"previous-6btns")];
        [self.prevButton setAlternateImage: imageFromRes(@"previous-6btns-pressed")];
        [self.nextButton setImage: imageFromRes(@"next-6btns")];
        [self.nextButton setAlternateImage: imageFromRes(@"next-6btns-pressed")];
    } else {
        [self.stopButton setImage: imageFromRes(@"stop_dark")];
        [self.stopButton setAlternateImage: imageFromRes(@"stop-pressed_dark")];

        [self.playlistButton setImage: imageFromRes(@"playlist_dark")];
        [self.playlistButton setAlternateImage: imageFromRes(@"playlist-pressed_dark")];
        _repeatImage = imageFromRes(@"repeat_dark");
        _pressedRepeatImage = imageFromRes(@"repeat-pressed_dark");
        _repeatAllImage  = imageFromRes(@"repeat-all-blue_dark");
        _pressedRepeatAllImage = imageFromRes(@"repeat-all-blue-pressed_dark");
        _repeatOneImage = imageFromRes(@"repeat-one-blue_dark");
        _pressedRepeatOneImage = imageFromRes(@"repeat-one-blue-pressed_dark");
        _shuffleImage = imageFromRes(@"shuffle_dark");
        _pressedShuffleImage = imageFromRes(@"shuffle-pressed_dark");
        _shuffleOnImage = imageFromRes(@"shuffle-blue_dark");
        _pressedShuffleOnImage = imageFromRes(@"shuffle-blue-pressed_dark");

        [self.volumeDownButton setImage: imageFromRes(@"volume-low_dark")];
        [self.volumeTrackImageView setImage: imageFromRes(@"volume-slider-track_dark")];
        [self.volumeUpButton setImage: imageFromRes(@"volume-high_dark")];
        [self.volumeSlider setUsesBrightArtwork: NO];

        if (self.nativeFullscreenMode) {
            [self.effectsButton setImage: imageFromRes(@"effects-one-button_dark")];
            [self.effectsButton setAlternateImage: imageFromRes(@"effects-one-button-pressed-dark")];
        } else {
            [self.effectsButton setImage: imageFromRes(@"effects-double-buttons_dark")];
            [self.effectsButton setAlternateImage: imageFromRes(@"effects-double-buttons-pressed_dark")];
        }

        [self.fullscreenButton setImage: imageFromRes(@"fullscreen-double-buttons_dark")];
        [self.fullscreenButton setAlternateImage: imageFromRes(@"fullscreen-double-buttons-pressed_dark")];

        [self.prevButton setImage: imageFromRes(@"previous-6btns-dark")];
        [self.prevButton setAlternateImage: imageFromRes(@"previous-6btns-dark-pressed")];
        [self.nextButton setImage: imageFromRes(@"next-6btns-dark")];
        [self.nextButton setAlternateImage: imageFromRes(@"next-6btns-dark-pressed")];
    }
    [self.repeatButton setImage: _repeatImage];
    [self.repeatButton setAlternateImage: _pressedRepeatImage];
    [self.shuffleButton setImage: _shuffleImage];
    [self.shuffleButton setAlternateImage: _pressedShuffleImage];

    BOOL b_mute = ![[VLCCoreInteraction sharedInstance] mute];
    [self.volumeSlider setEnabled: b_mute];
    [self.volumeSlider setMaxValue: [[VLCCoreInteraction sharedInstance] maxVolume]];
    [self.volumeUpButton setEnabled: b_mute];

    // configure optional buttons
    _hideEffectsButtonConstraint = [NSLayoutConstraint constraintWithItem:self.effectsButton
                                                      attribute:NSLayoutAttributeWidth
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:nil
                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                     multiplier:1
                                                       constant:0];
    if (!var_InheritBool(getIntf(), "macosx-show-effects-button"))
        [self removeEffectsButton:YES];

    _hideRepeatButtonConstraint = [NSLayoutConstraint constraintWithItem:self.repeatButton
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1
                                                                 constant:0];
    _hideShuffleButtonConstraint = [NSLayoutConstraint constraintWithItem:self.shuffleButton
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1
                                                                constant:0];
    b_show_playmode_buttons = var_InheritBool(getIntf(), "macosx-show-playmode-buttons");
    if (!b_show_playmode_buttons)
        [self removePlaymodeButtons:YES];

    _hidePrevButtonConstraint = [NSLayoutConstraint constraintWithItem:self.prevButton
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1
                                                                constant:0];
    _hideNextButtonConstraint = [NSLayoutConstraint constraintWithItem:self.nextButton
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1
                                                              constant:0];
    b_show_jump_buttons = var_InheritBool(getIntf(), "macosx-show-playback-buttons");
    if (!b_show_jump_buttons)
        [self removeJumpButtons:YES];

    [[[VLCMain sharedInstance] playlist] playbackModeUpdated];

}

#pragma mark -
#pragma mark interface customization


- (void)toggleEffectsButton
{
    if (config_GetInt(getIntf(), "macosx-show-effects-button"))
        [self addEffectsButton:NO];
    else
        [self removeEffectsButton:NO];
}

- (void)addEffectsButton:(BOOL)b_fast
{
    if (!self.effectsButton)
        return;

    [self.effectsButton removeConstraint:_hideEffectsButtonConstraint];

    if (!self.nativeFullscreenMode) {
        if (self.darkInterface) {
            [[self.fullscreenButton animator] setImage: imageFromRes(@"fullscreen-double-buttons_dark")];
            [[self.fullscreenButton animator] setAlternateImage: imageFromRes(@"fullscreen-double-buttons-pressed_dark")];
        } else {
            [[self.fullscreenButton animator] setImage: imageFromRes(@"fullscreen-double-buttons")];
            [[self.fullscreenButton animator] setAlternateImage: imageFromRes(@"fullscreen-double-buttons-pressed")];
        }
    }

    [self.bottomBarView setNeedsDisplay:YES];
}

- (void)removeEffectsButton:(BOOL)b_fast
{
    if (!self.effectsButton)
        return;

    [self.effectsButton addConstraint:_hideEffectsButtonConstraint];

    if (!self.nativeFullscreenMode) {
        if (self.darkInterface) {
            [[self.fullscreenButton animator] setImage: imageFromRes(@"fullscreen-one-button_dark")];
            [[self.fullscreenButton animator] setAlternateImage: imageFromRes(@"fullscreen-one-button-pressed_dark")];
        } else {
            [[self.fullscreenButton animator] setImage: imageFromRes(@"fullscreen-one-button")];
            [[self.fullscreenButton animator] setAlternateImage: imageFromRes(@"fullscreen-one-button-pressed")];
        }
    }
}

- (void)toggleJumpButtons
{
    b_show_jump_buttons = config_GetInt(getIntf(), "macosx-show-playback-buttons");

    if (b_show_jump_buttons)
        [self addJumpButtons:NO];
    else
        [self removeJumpButtons:NO];
}

- (void)addJumpButtons:(BOOL)b_fast
{
    [self.prevButton removeConstraint:_hidePrevButtonConstraint];
    [self.nextButton removeConstraint:_hideNextButtonConstraint];

    if (self.darkInterface) {
        [[self.forwardButton animator] setImage:imageFromRes(@"forward-6btns-dark")];
        [[self.forwardButton animator] setAlternateImage:imageFromRes(@"forward-6btns-dark-pressed")];
        [[self.backwardButton animator] setImage:imageFromRes(@"backward-6btns-dark")];
        [[self.backwardButton animator] setAlternateImage:imageFromRes(@"backward-6btns-dark-pressed")];
    } else {
        [[self.forwardButton animator] setImage:imageFromRes(@"forward-6btns")];
        [[self.forwardButton animator] setAlternateImage:imageFromRes(@"forward-6btns-pressed")];
        [[self.backwardButton animator] setImage:imageFromRes(@"backward-6btns")];
        [[self.backwardButton animator] setAlternateImage:imageFromRes(@"backward-6btns-pressed")];
    }

    [self toggleForwardBackwardMode: YES];
}

- (void)removeJumpButtons:(BOOL)b_fast
{
    if (!self.prevButton || !self.nextButton)
        return;

    [self.prevButton addConstraint:_hidePrevButtonConstraint];
    [self.nextButton addConstraint:_hideNextButtonConstraint];

    if (self.darkInterface) {
        [[self.forwardButton animator] setImage:imageFromRes(@"forward-3btns-dark")];
        [[self.forwardButton animator] setAlternateImage:imageFromRes(@"forward-3btns-dark-pressed")];
        [[self.backwardButton animator] setImage:imageFromRes(@"backward-3btns-dark")];
        [[self.backwardButton animator] setAlternateImage:imageFromRes(@"backward-3btns-dark-pressed")];
    } else {
        [[self.forwardButton animator] setImage:imageFromRes(@"forward-3btns")];
        [[self.forwardButton animator] setAlternateImage:imageFromRes(@"forward-3btns-pressed")];
        [[self.backwardButton animator] setImage:imageFromRes(@"backward-3btns")];
        [[self.backwardButton animator] setAlternateImage:imageFromRes(@"backward-3btns-pressed")];
    }

    [self toggleForwardBackwardMode: NO];
}

- (void)togglePlaymodeButtons
{
    b_show_playmode_buttons = config_GetInt(getIntf(), "macosx-show-playmode-buttons");

    if (b_show_playmode_buttons)
        [self addPlaymodeButtons:NO];
    else
        [self removePlaymodeButtons:NO];
}

- (void)addPlaymodeButtons:(BOOL)b_fast
{
    [self.repeatButton removeConstraint:_hideRepeatButtonConstraint];
    [self.shuffleButton removeConstraint:_hideShuffleButtonConstraint];

    if (self.darkInterface) {
        [[self.playlistButton animator] setImage:imageFromRes(@"playlist_dark")];
        [[self.playlistButton animator] setAlternateImage:imageFromRes(@"playlist-pressed_dark")];
    } else {
        [[self.playlistButton animator] setImage:imageFromRes(@"playlist-btn")];
        [[self.playlistButton animator] setAlternateImage:imageFromRes(@"playlist-btn-pressed")];
    }
}

- (void)removePlaymodeButtons:(BOOL)b_fast
{
    [self.repeatButton addConstraint:_hideRepeatButtonConstraint];
    [self.shuffleButton addConstraint:_hideShuffleButtonConstraint];

    if (self.darkInterface) {
        [[self.playlistButton animator] setImage:imageFromRes(@"playlist-1btn-dark")];
        [[self.playlistButton animator] setAlternateImage:imageFromRes(@"playlist-1btn-dark-pressed")];
    } else {
        [[self.playlistButton animator] setImage:imageFromRes(@"playlist-1btn")];
        [[self.playlistButton animator] setAlternateImage:imageFromRes(@"playlist-1btn-pressed")];
    }
}

#pragma mark -
#pragma mark Extra button actions

- (IBAction)stop:(id)sender
{
    [[VLCCoreInteraction sharedInstance] stop];
}

// dynamically created next / prev buttons
- (IBAction)prev:(id)sender
{
    [[VLCCoreInteraction sharedInstance] previous];
}

- (IBAction)next:(id)sender
{
    [[VLCCoreInteraction sharedInstance] next];
}

- (void)setRepeatOne
{
    [self.repeatButton setImage: _repeatOneImage];
    [self.repeatButton setAlternateImage: _pressedRepeatOneImage];
}

- (void)setRepeatAll
{
    [self.repeatButton setImage: _repeatAllImage];
    [self.repeatButton setAlternateImage: _pressedRepeatAllImage];
}

- (void)setRepeatOff
{
    [self.repeatButton setImage: _repeatImage];
    [self.repeatButton setAlternateImage: _pressedRepeatImage];
}

- (IBAction)repeat:(id)sender
{
    vlc_value_t looping,repeating;
    intf_thread_t * p_intf = getIntf();
    playlist_t * p_playlist = pl_Get(p_intf);

    var_Get(p_playlist, "repeat", &repeating);
    var_Get(p_playlist, "loop", &looping);

    if (!repeating.b_bool && !looping.b_bool) {
        /* was: no repeating at all, switching to Repeat One */
        [[VLCCoreInteraction sharedInstance] repeatOne];
        [self setRepeatOne];
    }
    else if (repeating.b_bool && !looping.b_bool) {
        /* was: Repeat One, switching to Repeat All */
        [[VLCCoreInteraction sharedInstance] repeatAll];
        [self setRepeatAll];
    } else {
        /* was: Repeat All or bug in VLC, switching to Repeat Off */
        [[VLCCoreInteraction sharedInstance] repeatOff];
        [self setRepeatOff];
    }
}

- (void)setShuffle
{
    bool b_value;
    playlist_t *p_playlist = pl_Get(getIntf());
    b_value = var_GetBool(p_playlist, "random");

    if (b_value) {
        [self.shuffleButton setImage: _shuffleOnImage];
        [self.shuffleButton setAlternateImage: _pressedShuffleOnImage];
    } else {
        [self.shuffleButton setImage: _shuffleImage];
        [self.shuffleButton setAlternateImage: _pressedShuffleImage];
    }
}

- (IBAction)shuffle:(id)sender
{
    [[VLCCoreInteraction sharedInstance] shuffle];
    [self setShuffle];
}

- (IBAction)togglePlaylist:(id)sender
{
    [[[VLCMain sharedInstance] mainWindow] changePlaylistState: psUserEvent];
}

- (IBAction)volumeAction:(id)sender
{
    if (sender == self.volumeSlider)
        [[VLCCoreInteraction sharedInstance] setVolume: [sender intValue]];
    else if (sender == self.volumeDownButton)
        [[VLCCoreInteraction sharedInstance] toggleMute];
    else
        [[VLCCoreInteraction sharedInstance] setVolume: AOUT_VOLUME_MAX];
}

- (IBAction)effects:(id)sender
{
    [[[VLCMain sharedInstance] mainMenu] showAudioEffects: sender];
}

#pragma mark -
#pragma mark Extra updaters

- (void)updateVolumeSlider
{
    int i_volume = [[VLCCoreInteraction sharedInstance] volume];
    BOOL b_muted = [[VLCCoreInteraction sharedInstance] mute];

    if (b_muted)
        i_volume = 0;

    [self.volumeSlider setIntValue: i_volume];

    i_volume = (i_volume * 200) / AOUT_VOLUME_MAX;
    NSString *volumeTooltip = [NSString stringWithFormat:_NS("Volume: %i %%"), i_volume];
    [self.volumeSlider setToolTip:volumeTooltip];

    [self.volumeSlider setEnabled: !b_muted];
    [self.volumeUpButton setEnabled: !b_muted];
}

- (void)updateControls
{
    [super updateControls];

    bool b_input = false;
    bool b_seekable = false;
    bool b_plmul = false;
    bool b_control = false;
    bool b_chapters = false;

    playlist_t * p_playlist = pl_Get(getIntf());

    PL_LOCK;
    b_plmul = playlist_CurrentSize(p_playlist) > 1;
    PL_UNLOCK;

    input_thread_t * p_input = playlist_CurrentInput(p_playlist);
    if ((b_input = (p_input != NULL))) {
        /* seekable streams */
        b_seekable = var_GetBool(p_input, "can-seek");

        /* check whether slow/fast motion is possible */
        b_control = var_GetBool(p_input, "can-rate");

        /* chapters & titles */
        //FIXME! b_chapters = p_input->stream.i_area_nb > 1;

        vlc_object_release(p_input);
    }

    [self.stopButton setEnabled: b_input];

    if (b_show_jump_buttons) {
        [self.prevButton setEnabled: (b_seekable || b_plmul || b_chapters)];
        [self.nextButton setEnabled: (b_seekable || b_plmul || b_chapters)];
    }

    [[[VLCMain sharedInstance] mainMenu] setRateControlsEnabled: b_control];
}

@end
