[![DOI](https://zenodo.org/badge/429406115.svg)](https://zenodo.org/badge/latestdoi/429406115)

# Neuropixels trajectory explorer
Neuropixels trajectory explorer with the Allen CCF mouse atlas or Waxholm rat atlas. See changelog below for history of updates.

## This branch
**NOTE: This fork is made in order to develop functionality for a different project. It still works but is substantially refactored comapared with the original and so will likely diverge. **


For example, you can set the probe position at the command line as follows:
```matlab
% Load atlas then feed in as input args. This is optional but it makes re-starting the GUI faster
[tv,av,st] = nte.loadAtlas;
pa_gui = neuropixels_trajectory_explorer(tv,av,st);

% Now set the entry and end points of the probe
nte.set_probe_entry([],[],pa_gui,[2,2,0,0])
nte.set_probe_endpoint([],[],pa_gui,[2,2,5,0,90])
```

**Keep the GUI up-to-date:** there are semi-regular upgrades (sometimes just a feature, sometimes something critical like getting a better estimate of distances and angles), so make sure to pull the current repository whenever planning a new trajectory.

Mouse CCF scaling, rotation, and bregma notes:
* the CCF is slightly stretched in the DV axis (because it's based on a single mouse with an unsually tall brain), currently estimated here as 94.3%
* The CCF AP rotation is arbitrary with reference to the skull, and this angle has been estimated as 5 degrees (from https://www.biorxiv.org/content/10.1101/2022.05.09.491042v3). This is implemented here, with the CCF being tilted nose-down by 5 degrees.
* Bregma has been approximated in AP by matching the Paxinos atlas slice at AP=0 to the CCF, the ML position is the midline, and the DV position is a very rough approximation from matching an MRI image (this DV coordinate shouldn't be used - all actual coordinates should be measured from the brain surface for better accuracy)

Any issues/bugs/suggestions, please open a github issue by clicking on the 'Issues' tab above and pressing the green 'New issue' button.

## Requirements, setup, starting
- Mouse: download the Allen CCF mouse atlas (all files at http://data.cortexlab.net/allenCCF/)
(note on where these files came from: they are a re-formatted version of [the original atlas](http://download.alleninstitute.org/informatics-archive/current-release/mouse_ccf/annotation/ccf_2017/), which has been [processed with this script](https://github.com/cortex-lab/allenCCF/blob/master/setup_utils.m))

- Rat: download the Waxholm rat atlas and unzip (https://www.nitrc.org/projects/whs-sd-atlas/)

- Download/clone this repository

### If you have MATLAB
- Download/clone the NPY-matlab repository: https://github.com/kwikteam/npy-matlab
(this is code to load the formatted CCF atlas)

- Add to MATLAB path: the folders with the atlas, the NPY-matlab repository, and this repository
(File > Set Path > Add with subfolders... > select the downloaded folder (have to do this for each folder separately), then hit 'Save' and 'Close')

- Run the command in MATLAB:

Mouse:
```matlab
neuropixels_trajectory_explorer
```
Rat: 
```matlab
neuropixels_trajectory_explorer_rat
```

### If you don't have MATLAB
- Run neuropixels_trajectory_explorer_installer.exe (also installs MATLAB runtime environment)
- The first time the explorer is run, you will be prompted to select the folder where you installed the CCF atlas. Navigate to the folder with the atlas and hit 'ok'.

## Instructions

A video demo of usage (from the [UCL Neuropixels 2021 course](https://www.ucl.ac.uk/neuropixels/training/2021-neuropixels-course) on a slightly older version) is here: https://www.youtube.com/watch?v=ZtiX0iunUTM

### Overview of interface
![image](https://github.com/petersaj/neuropixels_trajectory_explorer/blob/main/wiki/overview.PNG)

#### Control panel
- Probe controls: 
  - arrow keys (translate), SHIFT+arrow keys (rotate probe by moving bottom), ALT+arrow keys (depth along probe axis)
  - Set entry: move probe to specific entry coordinates
  - Set endpoint: move probe to specific endpoint coordinates (NOTE: this uses the roughly approximated bregma DV position)
- 3D areas: pick an area (through a comprehensive list, search, or hierarchy) to draw in 3D on the atlas
  - List areas: choose from list all areas in the CCF
  - Search areas: search CCF areas (e.g. search for "CA1" to find what the CCF calls "Field CA1")
  - Hierarchy areas: drill down to areas on the hierarchy, select structures at any level of the hierarchy (e.g. select all "primary visual cortex" instead of by layer like "primary visual cortex layer 1")
  - Remove areas: select previously drawn 3D areas to remove 
- Toggle visibility: turn on/off visibility ('Slice' switches between displaying anatomy, CCF-parsed regions, or nothing)
  - Slice: toggle brain slice between anatomy (greyscale), CCF regions (with CCF-assigned colors), or off
  - Brain outline: toggle brain outline visibility on/off
  - Probe: toggle probe visibility on/off
  - 3D areas: toggle 3D areas visibility on/off
  - Dark mode: toggle white/black font and background (can make some colors like yellow cerebellum easier to see)
- Other: in development, not currently in regular use

#### Atlas
The atlas can be rotated by clicking and dragging (the slice updates when the mouse is released). The probe can be moved with the arrow keys (+SHIFT: rotation, +ALT: depth).

#### Probe areas
These are the regions that the probe (blue line) is passing through


### Experimental use of Neuropixels coordinates
The coordinates of the probe are displayed above the atlas relative to **bregma (anterior/posterior and medial/lateral)** and the **brain surface (depth, axis along the probe)**

![image](https://github.com/petersaj/neuropixels_trajectory_explorer/blob/main/wiki/positions.png)

The angles of the manipulator are displayed as the **azimuth (polar) relative to the line from tail to nose, where 0 degrees means the probe is coming straight from behind the mouse**, and to the **elevation (pitch) relative to the horizontal, where 90 degrees means the probe is going straight downward**.

![image](https://github.com/petersaj/neuropixels_trajectory_explorer/blob/main/wiki/angles.png)


During the experiment:
- Position the manipulator angles in azimuth/polar and elevation/pitch
- Position the probe tip over bregma and zero the AP/ML coordinates
- Move the probe tip until it's lightly touching the brain at the desired AP/ML coordinates
- Zero the depth coordinate (along the probe-axis), then descend until the desired depth is reached

## Changelog
2022-09-23: Changed CCF rotation to 5 degrees AP (clarification from IBL paper)
2022-07-20: Updated position readout for clarification
2022-05-20: Added rat trajectory explorer ('neuropixels_trajectory_explorer_rat')
2022-05-18: Changed coordinate system to allow for more flexible coordinate changes in future (including user-set scalings/rotations)
2022-05-17: Rotated CCF 7 degrees in AP to line up to a leveled bregma-lambda (angle from https://www.biorxiv.org/content/10.1101/2022.05.09.491042v3.full.pdf)
2021-12-15: Added 'set endpoint' functionality, approximated bregma DV (from MRI - very rough)


