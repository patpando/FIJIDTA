# Fiji Derivative Threshold Analysis for centered circles (FIJIDTAcc)

Extranuclear DNA bodies are cellular structures containing DNA that are separate from the primary nucleus and surrounded by a nuclear envelope. Extranuclear DNA bodies arise in mammalian cells primarily during mitosis and are called micronuclei (MN). MN have been extensively studied as they are frequently observed in human cancer cells, and their presence correlates with DNA damage and/or aberrant chromosome segregation. Similar to human cancer cells, the model eukaryote Tetrahymena thermophila produces extranuclear DNA bodies, called chromatin extrusion bodies (EBs). EBs are structurally similar to MN and are also correlated with DNA damage and chromatin disruptions. Importantly, the molecular processes that produce and govern EB fate in Tetrahymena are not fully understood. Currently, the quantification of MN and EBs is primarily achieved by calculating their frequency and/or manually outlining their shape to measure area. Although useful, manual outlining is time-consuming, difficult to reproduce, and prone to human bias. To overcome these limitations, we propose a semi-automated method of measuring an EB’s area: FIJI derivative threshold analysis for centered circles (FIJIDTAcc). This method is reproducible and robust across microscope modalities, enabling the scientific community to more accurately compare the sizes of extranuclear DNA bodies across experiments and biological systems.

# User Manual

This instruction is for the ImageJ/FIJI script named FIJI Derivative Threshold Analysis for centered circles (FIJIDTAcc), which robustly determines the area of Tetrahymena chromatin extrusion bodies (EBs). FIJI is an open-source image analysis software that can run scripts like FIJIDTAcc written in the ImageJ macro language (Schindelin 2012). The algorithm used in FIJIDTAcc defines an area as a function of initial parameters and coordinates, thereby enabling a more consistent analysis of EBs. The initial coordinates can be overlaid on Tiff images of DAPI-stained cells captured on a wide-field microscope at 40x or 63x magnification. Step 1 is to open FIJI and FIJIDTAcc. Steps 2 and 3 are to open and mark images. Step 4 begins with understanding how to set the initial parameters, then pressing run. Depending on your chosen parameters, the workflow between steps 4 and 5 will change. Regardless, step 5 focuses on analyzing the resulting areas and CSV file.

# Step 1:
 <img width="975" height="229" alt="image" src="https://github.com/user-attachments/assets/c0201d95-9bc1-4fd9-9f64-e0b3c5a715fe" />


Open FIJI and the FIJIDTA script. Although we generate our images using widefield fluorescence microscopy (Appendix Figure 1), FIJIDTA could eventually be applied to other imaging modalities. 

Open FIJI by double left-clicking the ImageJ/ FIJI icon. Once your version of FIJI is downloaded, open the general user interface (GUI shown below).

 <img width="767" height="138" alt="image" src="https://github.com/user-attachments/assets/f2eecc8d-d2de-410a-99f0-45c5991f9ebc" />


If FIJI is not already installed, go to Fiji Downloads (https://imagej.net/software/fiji/downloads) and follow the installation prompts to download FIJI.

FIJIDTAcc can be opened through the FIJI GUI by going to file, then clicking open (or pressing Ctrl+O) and choosing the file. FIJIDTAcc can also be dragged and dropped from the files window to the gray bar in the GUI. The opened window with the code should have a “Run” button at the top or bottom.

Download the FIJIDTAcc script by going to: (https://github.com/patpando/FIJIDTA/blob/main/20250511_FIJIDTAccV1A.ijm)

# Step 2:
 <img width="975" height="236" alt="image" src="https://github.com/user-attachments/assets/52e587b8-9e15-4f88-847b-23d2fa6acdc4" />


# Step 3:
 
<img width="975" height="390" alt="image" src="https://github.com/user-attachments/assets/68703a87-b7eb-449c-9d88-4f3ce0dff169" />






# Step 4:
 <img width="975" height="341" alt="image" src="https://github.com/user-attachments/assets/b1866774-79cf-4c88-8be5-236a46863414" />


 Understanding your input parameters and what setting you want to use. 

To find the pixel dimensions of an open image using the FIJI GUI, click on “Image” in the GUI, then click on “Properties…” (or press Ctrl+Shift+P) (example shown below).

<img width="450" height="697" alt="image" src="https://github.com/user-attachments/assets/c514190c-30aa-4664-8d71-e948e9e45cdf" />

Before running FIJIDTAcc, a user should be familiar with the details of their image data and understand the meanings of the parameters in the initial dialog box (shown below and in Figure 16). Default parameters are set to measure EBs for Dr. Lee’s lab at Western Washington University, taken at 40x magnification. We expect to measure 3D images like the one shown in Appendix Figure 2. Micron inputs should be divisible by pixel width, so the sampled area is a known number of pixels. The code tends to round down or use the “floor” function when dividing input microns by pixel dimensions. For example, if an even number of slices, n, is to be compared, then n-1 slices are checked. To better understand the slice comparison, refer to Supplemental Figure 1. Default parameters, along with further explanations, are shown below. These variables can be changed in the gray dialog box below after pressing run or in the code itself. 
 


<img width="975" height="770" alt="image" src="https://github.com/user-attachments/assets/f11bd0a3-d953-4445-8c14-bc2adb22a8df" />


Variables (Defaults)
1.	Width & height of EB box (8.5*8.5 microns): The EB box is an automatically saved TIFF image centered on the EB’s highest-intensity pixel. The EB’s selected area is saved as an overlay. Derivative Threshold Analysis (DTA, in FIJIDTA) is run from the center of the EB box, and the length of the sampling lines is half the width and height of the EB box (Figure 17A). 

2.	DTA line width (0.85 microns): Sampling lines start in the center of the EB box, and the eight lines stop in the four corners and four sides of the box. The most significant drop in intensity will be determined from a plot of the average intensity across the line’s width vs the length of the line. Further details on the algorithm are provided in the methods section (Figure 17B).

3.	Minimum radius circle size (0.5 microns): If the first circle’s radius is smaller than the parameter’s input, then the minimum radius circle size is used. If the minimum circle is used, then “SC” (Small Circle) will be saved in the table instead of “C” (Figure 17C).

4.	Number of Z-axis slices checked (9 microns): The number of slices used to determine the EB's most in-focus slice is set by the user in microns. The initial chosen slice and the slices above and below are checked. The total number of checked slices is rounded down to the nearest odd number by dividing the input by the voxel depth. Voxel depth can be found under image properties (or by pressing Ctrl+Shift+P) (Figure 18).

5.	Width and height of the big EB context box (50 microns): The EB context box is the same as the EB box, except it shows the selection at the center of a larger image to provide context, and the images are saved to a folder that is automatically created. It is used only for post-processing results, as explained in the checkboxes section.

6.	Minimum selection area (1 pixel): When slices are compared or batch mode is true, the selection must be at least the minimum size to be of good quality. Use the variable “minAreaSizeum” under the pixel size-dependent global variables to change unit

7.	Minimum circularity (0.5): When slices are compared or when batch mode is true, the selection is evaluated using the equation (4*pi*Area)/Perimeter^2, and it must have a resulting circularity greater than the minimum to be considered of good quality. To run watershed, the selection must be above the minimum + the watershed bias amount (see code settings for more info). The amount must be between 0 and 1. 

For more information on the watershed separation algorithm, refer to
 Appendix B Figure 1

8.	Saturated threshold (4095): Detect EBs that are saturated and have the highest possible intensity. The input to this parameter is also used to set the upper bound for the threshold. When a threshold is set, the minimum/lower bound threshold will vary with the threshold results, but the maximum/upper bound threshold should be large enough to include all pixel intensities.

9.	Character(s) (“_set”): The title of the table is made using the name of the first file in the image folder. The table title’s name is the first file’s name minus the character(s) input and everything after. Image titles follow a date_strain_set#_pos# format.

 <img width="668" height="490" alt="image" src="https://github.com/user-attachments/assets/ed7baa7d-be22-40b4-9742-fbe9a28caa2f" />

10.	File directory of images: File where images are held. If default setting is chosen, images should be pre-marked.  
 
<img width="659" height="484" alt="image" src="https://github.com/user-attachments/assets/ce878509-f180-4078-8b65-ed2eb2b8ffc8" />

11.	File directory for results: The file directory where the resulting EB boxes and the results table are automatically saved is selected by clicking the “browse” button. The file can be created before running FIJIDTAcc or by pressing Create New Folder in the pop-up file directory window shown above in the red box.



Checkboxes

View manual segmentation options (False): A pop-up dialog appears after pressing OK, presenting the user with 5 options to manually segment EBs. These options are further discussed in the next section.

Grayscale images (True): If selected, all images will be converted to grayscale. Change “run("Grays");” in the code to change your images to any allowed FIJI color.

 <img width="944" height="68" alt="image" src="https://github.com/user-attachments/assets/ffc484b0-2f0a-4edf-a0e4-bdf7e614575b" />

Table with double header (True): If the box is selected, then the table's top labels are made in the top row. 

Images are pre-marked (True): If the box is selected, then FIJIDTAcc assumes images have overlay coordinates saved to them. If the box is not selected, users will mark images as they are being processed. 

Batch mode (True): If the box is selected, then EBs are automatically assigned a quality based on their selection’s properties and the EBs' first circle. More details on the analysis of selection properties are provided in Figure 16 of the methods section. If the box is not checked, the user decides the final quality of each EB.

Post-process results (True): If the box is selected, EBs are saved in the EB box and the context box. All the EBs are then placed into a stack after they have all been processed. The user can navigate the stack and adjust the quality of an EB if needed. 

Manual Checkbox (MC) segmentation options

<img width="764" height="475" alt="image" src="https://github.com/user-attachments/assets/f62c819f-aa06-4567-b15d-ccceb2fc051a" />

 
 <img width="1060" height="351" alt="image" src="https://github.com/user-attachments/assets/2e35a58b-0a05-43ca-9860-8c67014c444c" />


MC 1, Only use user mark (onlyUseUserMark = False): No slices are checked, and analysis is only done from the user's coordinates. If users don’t care about comparing slices or automatic thresholds, it’s recommended to use this feature with the “Manually select everything” checkbox to create selections from user-provided coordinates. 

MC 2 If EB is of bad quality, center the selection around the user mark (ifBadSelectFromUserMark = False): After all the slices have been compared and no good quality selections have been found, then the selection is centered around the user's mark. It's recommended to use this feature with the third or fourth checkbox, which would allow users to create a selection around their chosen coordinate.

MCs 3, 4, and 5 create a convex hull around the threshold selection. The user can press OK when prompted in a dialog box, or click around the signal to create their own selection.



 
MC 3 Researchers manually outline good and bad EBs (ResearcherManualOutlineBadGood = False): After slices are compared and the EB’s best slice and selection is found, users can manually change the convex hull selection, whether the selection was Good or Bad quality. 

MC 4 If EB’s selection is of bad quality, then the user creates a selection (ResearcherManualOutlineBad = False): If the box is checked and EB’s quality is bad, then the user creates a convex hull selection by clicking around the signal.

MC 5 Manually select everything (ManualSelectAll = False): if true, then every time the function getArea is called, the user is asked to check the selection and modify it, if necessary. If many slices are being compared, the analysis will take longer, but this allows users to view or create every selection for their EBs. 


Code settings (change these near the top of the code)

Watershed bias (Wbias = 0.25): The watershed bias is added to the minimum circularity when the algorithm checks whether to watershed a selection or not. 

Gaussian Sigma (gaussianSigma = 0): If this is greater than 0, then a Gaussian blur is applied to the analyzed EBs in the getArea function.

Skip post-processing questions (skipPostProQuestions = False): If a large number of parameters or thresholds are being compared, a user can set this to true to save the post-processing stacks, without needing to check every EB. Although this allows the user to run FIJIDTAcc for an extended period, the printed success rate of good EBs may be inaccurate if selections are incorrect in a qualitative way.   

Make graph (makeGraph = True): If true, a graph will be created with the number of EBs on the y-axis and the EB area on the x-axis. Must be False when running a parameter sweep. The graphArea function also prints the number of good EBs and their average area and intensity. 

Sort coordinates left to right (sortCoord = False): Coordinates are sorted by the order they were marked in. If true, coordinates are processed from left to right in the image. 

Print Statistics (printStats = True): Prints the number of saturated EBs, the Number of EBs isolated with low circularity, and the number of EBs that went through the watershed separation algorithm. Also prints all the good EB areas on a single line in a log.txt file that’s saved in the results folder. This list of good EBs can be easily copied and pasted into the statistical analysis code written in Python.

Print intensity values (printIntensityValues = False): Prints all the EBs' mean intensity on a single line in a log.txt file that’s saved in the results folder. 

Threshold/ parameter sweeps (threshSweep = false): A user can run the same set of images under different parameters or threshold methods by uncommenting the code in green. If it’s a threshold sweep, set threshSweep to True. To comment or uncomment a line, use //. Once the array paraSweepArr is created, uncomment a set or set its values. The for loop wraps the rest of the main method, so its closing bracket must be uncommented before the first function. Uncomment one of the global variables to have it change as the for-loop parses through the paraSweepArr. File.makeDirectory and saveImg= will name the new folders with the parameter sweep variables. 

Post process folder names can be changed by changing the text “bigImg” and “smallImg” under the parameter sweep comments.   bigImgFileName = "bigImgs";   EBfileName = "smallImgs";

Every image is saved with “EB” added to the file name. Change the string under markNumLabel to change this. markNumLabel = "EB";

 Run FIJIDTA and follow workflow prompts.

If images are not pre-marked (the fourth checkbox is not checked):
If a user has never used FIJIDTAcc but has images to test its viability, then not checking the fourth checkbox is recommended. Once the run is clicked (or press Ctrl + R) in the script window, and parameters are filled out, the pop-up window shown below should appear.

 <img width="612" height="144" alt="image" src="https://github.com/user-attachments/assets/07ccb8d0-78a9-44d3-8d0e-85d283f20a83" />


The first image file in the chosen directory of images will be opened. Use the Z slider to move through slices and find EBs in the DAPI channel. If another stain was used to help identify EBs then move through channels. Additionally, identify an EB by examining its position in relation to the macronucleus (MAC) and micronucleus (MIC). When the cell is not dividing, the MIC should look pressed into the MAC or look like a part of the MAC, while an EB is separated from both. In addition, the channel with pH3Ser10 staining and the “empty” channel can be used to rule out DAPI-staining mitotic MICs and autofluorescence, respectively. (See Lee Lab protocols for more details on distinguishing EBs from other structures with DAPI signal.) Mark an EB by pressing the left click at its center on its estimated brightest slice. Then go to Edit-> Selection-> and click on Add to Manager in the FIJI GUI (or press Ctrl + T). Once all EBs in the image have been selected, press ok. From here, the default workflow is followed until the next image.   

 <img width="736" height="360" alt="image" src="https://github.com/user-attachments/assets/4201ecac-6d40-4e5d-b8aa-3c1f217a04f6" />

Examples of a micronucleus, macronucleus and EB.

Default settings using a collection of pre-marked images:

If a user has already marked images in a folder, press Run (or press Ctrl+R) and fill out the initial parameters. In the dialog box, click the first “Browse”, then find and select the marked images folder. After clicking “OK,” the pop-up windows below will appear, displaying the selected EB after the threshold is applied.
 
<img width="761" height="469" alt="image" src="https://github.com/user-attachments/assets/98305093-96a4-4390-9442-5df4a1957702" />


Manually determining the quality of the EB: If batch mode is not selected, the user is asked whether the EB is acceptable after a final threshold selection. Clicking “Yes” means the EB is good and will get a “G” in the table under “Quality”. Clicking “No” means the EB is bad and it will get a “B” in the table. Only EBs that are acceptable should be used when calculating the average EB size for a strain. 	

Automatic determination of EB quality: If batch mode is selected, then all the EBs will be processed, and their quality will automatically be determined. 
 
<img width="868" height="608" alt="image" src="https://github.com/user-attachments/assets/ea312dbb-c80a-4221-9dd5-c15cafa2ad95" />

# Step 5:

 
<img width="1268" height="254" alt="image" src="https://github.com/user-attachments/assets/3eb5866c-ea16-4c78-90c1-23963a3a9b3f" />



<img width="986" height="196" alt="image" src="https://github.com/user-attachments/assets/157abfe3-9819-44aa-97ea-e4f3957e67f7" />




Interpret results.
Details about the saved images: Depending on the quality of the EB, EB boxes will be saved with either “G_” or “B_” at the beginning of their title. Their title also includes the title of the TIFF image they come from and their EB number, which correlates to the order in which EBs were marked in the image. The pixel selection that determined the area is also saved with the image as an overlay.

Label: Filename of image where EB came from.

Mark: EB number in image. Decided by the user that marked the image. If sort coordinates is		true then it’s the marks number going from left to right.

Quality: If “G” then the EB is acceptable, and the selection can be used to calculate an average 		 area. If “B” then the EB is bad. If “S” then the EB is saturated.

Area: Area in microns of EB selection.

Mean: Mean pixel intensity of selected EB.

EB threshold: Threshold set from DTA that decides the selected signal region.

Watershed: A true or false result to whether the watershed function was run on the EB. 

Circularity: The selections circularity is measured using the equation (4pi(area/perimeter^2)).

Center X/ Center Y: Coordinates of the brightest pixel in EB and center of EB box.

Slice: Most in focus/ brightest determined slice.

User X Y: Users initial coordinate selection of center of EB.

User slice: User’s initial chosen slice of EB.

First circle: If “C”, then a circle with a DTA determined size was used. If “SC” then the default
 minimum circle size (chosen in the variables dialog box) was used.

First radius in microns: Radius of first circle in microns.

Slices: All the slices of an image become columns in the table, but only the compared slices
become populated with analysis details. Going from left to right the input for every slice
is quality, area, intensity, and the X Y center. If the center pixel was the center of
multiple pixels with the same intensity, then the intensity column will include a width “W” and height “H” of the size of the multiple pixel selection.


DTA direction and intensity: Each line created for DTA has a column labeled with its direction
and the result is the intensity where there is the steepest drop in intensity. 
EB quality checks: If the EB did not meet one of the quality criteria (minimum circularity, center 
of mass in 1st circle, centroid in 1st circle or corner selected), then a 1 is placed in the 
column.

To run the analysis on the data using R (Excel data) or Python (log data) use the GitHub link:

https://github.com/patpando/MannWhitU-WilcoxonStatsR-Python

patpando/MannWhitU-WilcoxonStatsR-Python: Run Mann-Whitney U Tests or Wilcoxon signed rank tests on R or Python



To contiue research into the methods of finding and measuring EBs using convolutional neural networks use links:

<img width="1055" height="829" alt="image" src="https://github.com/user-attachments/assets/ba4e7e3b-5e34-4d8f-83c0-2c2d7336a736" />


https://github.com/patpando/CNNEBFinder


https://github.com/patpando/CNN2EBSegmentation


<img width="598" height="845" alt="image" src="https://github.com/user-attachments/assets/38c660fd-ffca-4306-ab40-d056deccd137" />

Figure 6: The workflow researchers follow to obtain EB areas with FIJIDTAcc. The five main steps to analyze cells with EBs are listed. First, the user must capture images of a DAPI-stained slide and download the FIJI (link) and FIJIDTAcc (link) software. Second, the user opens their images and the FIJIDTAcc software in FIJI. Researchers follow steps 3I through 3V to mark their images in FIJI using the region of interest (ROI) manager and place images in a designated folder. The user runs FIJIDTAcc in the fourth step by filling out the dialog box and confirming the quality of each EB. In the end, the user will have a results folder with an Excel file that contains information on each EB's quality, area, mean intensity, and other relevant details. The folder will also contain a log.txt file and EBs saved in their respective EB boxes, titled “G/B_Label_EB#” in a folder. Scale bars =1 μm.


<img width="614" height="867" alt="image" src="https://github.com/user-attachments/assets/6d3bf90a-bb3d-4e13-97af-35e0904e9321" />

Figure 16: FIJIDTA's user interface and default parameters are shown. The initial dialog box that appears after a user presses Run includes labels indicating which category each input belongs to. The first 4 parameters are the analysis area around the user’s initial mark. Parameters 5,6, and 7 are result preferences. Parameters 8,9, and 10 are acquisition details. Parameters 11 and 12 are where the user enters the file paths after clicking Browse. Checkboxes 1-6 are the result and processing preferences. The 3rd checkbox, “Table with labels,” is shown with an example table and label. If it is selected, the results table displays all result labels in the first row. An example of the pop-up dialog box that appears with every image when the 4th checkbox “Images are pre-marked” is unchecked is shown. If the 5th checkbox, “Batch mode: Auto analyze an EB’s quality,” is not selected, after each EB is analyzed, the user answers a series of prompts to determine its quality. An example of the prompts with the EB from Figure 15A is shown. Batch mode relies on result preferences 6 and 7. Post-process results is the 6th checkbox and uses result preference 5. More details are explained in Figure 19. (scale bar =1 μm)


<img width="621" height="833" alt="image" src="https://github.com/user-attachments/assets/fc817a38-5e01-4a74-b098-8581c32517dc" />

Figure 19: Post Process Selections. If the 6th checkbox in the dialog box “Post process results” is selected, then parameter 5 will set the size of the large context box. After every EB is measured, selections are placed into the center of a stack. The user scrolls through images in the stack and answers the prompts. The EB from Figure 15A and 17 is shown. The dashed arrow represents how the user scrolls through slices to look at different EBs. The second EB’s max intensity is lowered to 500 and shows a selection that doesn’t encompass the whole signal. The first prompt allows the user to scroll through slices and look at selections. If any mislabeled selections are found, the user clicks OK and presses yes in the next pop-up dialog box. The example shows an EB that was labeled as good but should be changed to bad. If none are found, the user will press OK then no. (scale bar =1 μm)

<img width="938" height="981" alt="image" src="https://github.com/user-attachments/assets/06f23f25-60e0-4338-9bd0-07a1be153229" />
 
Supplemental Figure 1: An EB’s selections shown across 9 slices. The center slice 13 is the user’s chosen slice. The two leftmost columns show the EB without any selection. the third column shows the first circle made in the FIJIDTAcc analysis. The first circle is drawn across all 9 slices to find the highest-intensity pixel (HIP) within it. The HIP is represented by the white pixel. On the right, the selections are centered around the HIP in the fourth column, with the slice, area, and mean intensity shown. (Scale bar = 1 μm)

Citations
Schindelin, Johannes, Ignacio Arganda-Carreras, Erwin Frise, Verena Kaynig, Mark Longair, Tobias Pietzsch, Stephan Preibisch, et al. 2012. “Fiji: An Open-Source Platform for Biological-Image Analysis.” Nature Methods 9 (7): 676–82. https://doi.org/10.1038/nmeth.2019
Appendix A


 <img width="872" height="1249" alt="image" src="https://github.com/user-attachments/assets/4f2b460f-ad0e-4e8e-ba03-3bae61908a0e" />


Appendix A Figure 1. Light path and resolution in widefield fluorescence microscopy. (A) A fluorescence microscope passes white light through an excitation filter, which only allows a specific wavelength of light to pass through. The dichroic mirror reflects the excitation light into the objective. For DAPI visualization, the system uses filters, and a dichroic mirror optimized for ultraviolet (358 nanometer (nm)) excitation and blue (457 nm) emission wavelengths (λ). The objective focuses the light onto the fluorescent sample which emits wavelengths greater than the excitation wavelength. The longer wavelengths travel back through the objective, pass through the dichroic mirror and emission filter, and are collected by the detector via the tube lens. The diffraction pattern of a point source of light forms an Airy disk on the detector. (B) The numerical aperture (NA) of an objective is found by accounting for the refractive index (n), given by the medium between the sample and objective, and by knowing theta. The refractive index of air is 1 and of oil is 1.52. Theta is the half angle of light acceptance. (C) An objective with a low NA accepts less light, has less resolution, and creates larger airy disks compared to one with a high NA. (D) The Airy disk has a high intensity center with concentric rings surrounding it. With multiple point sources of light, the resolution between them can be chosen by the Rayleigh criterion λ0.61/NA.

<img width="635" height="892" alt="image" src="https://github.com/user-attachments/assets/3bec9233-4a7f-43c9-b1f9-9715488d1aac" />



Appendix A Figure 2: Creating a 3-dimensional image using fluorescence microscopy. (A) In the X Y dimension, the light (shown in white) represents the expected circular shape with a known radius (1.02 μm or 6 pixels) and area (3.27 μm2). The circle is captured on a grid of pixels to create the image. Each pixel is a known size (0.17 μm x 0.17 μm or 0.0289 μm2), allowing the area of the pixelated circle to be calculated (3.58 μm2). (B) The intensity gradient of an image is determined by the photon emission of the sample at a plane of focus. Ultraviolet light (shown in purple) excites the sample (the white sphere) which emits blue photons. Photons are captured by the detector which is made of silicon photodiodes. The photons interact with a poly silicon gate layer (dark blue), then excite electrons in a layer of silicon dioxide (gray). The electrons (black dots) are stored in a silicon well then converted to an intensity value with more electrons corresponding to a greater intensity. (C) The generated image is shown in black and white with a high intensity center and a gradual intensity change outwards. (D) A 3D intensity profile of the measured image is shown with an intensity range from 0 to 4096 and a grayscale color scheme applied. (E) 5 planes of focus in the X Y dimension are captured to represent the Z dimension and volume of the specimen (white sphere). (F) The specimen is represented by a sphere and the estimated area of the sphere sliced in 5 planes of focus. The 3D PSF kernel, which affects the intensity of every pixel, is represented in a cube and is a white oval in the center with cones of light emitted from the center to the top and bottom. The light captured from the expected specimen, the 3D PSF kernel and any accumulated noise are blended and convolved (*) together to create the measured image. 








Appendix B 

<img width="888" height="1263" alt="image" src="https://github.com/user-attachments/assets/df8f4620-d498-40b2-85e8-0a700c7767db" />

Appendix B Figure 1: The watershed separation algorithm. A large EB located close to the MAC & MIC, has the watershed algorithm applied to it after the threshold selection includes the MAC & MIC. When the threshold is set to 750, the EB selection is isolated and measured (shown in white). When the threshold is lowered to 700 it includes pixels that are shared by the MAC (shown in cyan) and an inaccurate area of the EB is measured. After the watershed algorithm is applied the EB is isolated and is measured with a more accurate area. The threshold selection is shown as a mask in the binary black and white images. Binary images are necessary to run the watershed algorithm within the selected area. The 3D intensity profile is an enlarged image from Figure 5. The green arrow denotes where separation occurred and the intensity valley between the EB and MAC. The highlighted orange section is in between the MAC & MIC’s intensity gradient. This difference in intensity did not cause watershed separation. (Scale bar = 1 μm)

