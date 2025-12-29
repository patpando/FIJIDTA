/*ReadMe: This code was written under advisement of WWU Professors Nick Galati and Suzanne Lee. Students: Patrick Pando, Maya Matsumoto,
Images should have overlay of point tool selection inside EBs and user selections should be on the Z slice with the highest estimated mean pixel intensity for Default setting.
FIJIDTA’s algorithm starts by opening a dialog box for paramters (function dialogVar). Then it sets variables, makes the table (function createTable) and images are opened using a for loop.
An open image's coordinates are placed in an array (function ROItoArr). From here a large portion of the code is focused on re-establishing the expert-placed mark to the EB's brightest slice
and highest intensity pixel (HIP) on that slice. To make this analysis dynamic, the function makeDerivativeCircle creates circles that vary in size depending on each EB's intensity profile.
First a circle is made from the user's coordinates (function firstCircle). This circle is created on a user set number of slices (variable zVol_um) to find every slice's HIP.
An EB box the size of boxmicrons is centered around the slice's HIP to make a selection. Each slice's selection is compared to find the highest mean intensity slice with good quality
(function checkSlices). The boundaries of an EB are determined by setting a local threshold through what I am calling Derivative Threshold Analysis (DTA).
DTA creates dynamic circle sizes and areas. From the HIP outwards, lines with half the length of the variable boxmicrons and a width defined by the variable lineWideum are created. 
Using the lines intensity profile the steepest drop in intensity is identified (function derivative). This sampling is done eight times rotating around the HIP (function DerivativeThresh)
and the EB boundary/threshold is set as the average of these eight values (function getArea). 
The watershed algorithm is also used to separate EBs from nearby DAPI staining, non-EB structures, like MICs and MACs (function watershed).
If auto analysis/ batchmode is chosen then an EBs circularity and selection quality will be checked to see if the EB is good, bad or saturated. Otherwhise an EBs quality is decided by the user.
If postprocessing is checked, then all the EBs will be saved with a big box (function bigbox). At the end of processing, the two files with the EB boxes will have all the images opened
and saved in a stack. These stacks will have the EB in the center with its overlay selection. When prompted the user can change the quality of the EB.
To customize parameters to a user's own lab, change intial variables in function getVar.
For error handling, commented print statements can be uncommented */
Dialog.create("Variables Used for Calculations");
Dialog.addNumber("Width & height of EB box (microns) ", 8.5);
Dialog.addNumber("Width of line for derivative threshold analysis (DTA) (microns) ", 0.85);
Dialog.addNumber("Minimum radius of circle size (microns) ", 0.5);
Dialog.addNumber("Amount of Z-axis microns checked for highest intensity slice (microns) ", 9);
Dialog.addNumber("Width and height of big EB context box (Only used for post processing) (microns)", 50);
Dialog.addNumber("Minimum selection area (pixels)", 1);
Dialog.addSlider("Minimum circularity ((4*pi*Area)/Perimeter^2)", 0, 1, 0.5);
Dialog.addNumber("DAPI channel", 2);
Dialog.addNumber("Intensity threshold to exclude saturated data points", 4095);
Dialog.addString("Everything after chosen character gets deleted from image title for table title", "_set");
Dialog.addDirectory("Choose a file of images", ""); // User should choose a file with marked .tiff images
Dialog.addDirectory("Choose a file to save images to", ""); // user is prompted to choose a file to save EB results table and EBbox images. User can make new file when prompted
Dialog.addCheckbox("View manual segmentation options", false);
Dialog.addCheckbox("Grayscale images", true);
Dialog.addCheckbox("Table with double header", true);
Dialog.addCheckbox("Images are premarked", true);
Dialog.addCheckbox("Batch mode: Auto analyze an EB's quality", true);
Dialog.addCheckbox("Post process results", true);
Dialog.show();
boxmicrons = Dialog.getNumber();
lineWidth_um = Dialog.getNumber();
minCirc_um = Dialog.getNumber();
zVol_um = Dialog.getNumber();
bigBoxmicrons = Dialog.getNumber();
minAreaPixels = Dialog.getNumber();
circularity = Dialog.getNumber();
channel = Dialog.getNumber();
saturated = Dialog.getNumber();
letter = Dialog.getString();
imgDir = Dialog.getString();
saveImg = Dialog.getString();
catchBadQManualSegment = Dialog.getCheckbox();
gray = Dialog.getCheckbox();
tableLabels = Dialog.getCheckbox();
choice = Dialog.getCheckbox();
batchMode = Dialog.getCheckbox();
postProccRes = Dialog.getCheckbox();
upperBoundThresh = saturated; //Variables are the same value but are distinguished when called in the code for readability 
Wbias = 0.25; // watershed bias: raise the circularity minimum for watershed by desired amount between 0-1
gaussianSigma = 0; // If greater than 0, a gaussian blur is applied in the getArea function, to just the saved EB box
skipPostProQuestions = false; //set to true when running post process but don't want to check selections. Recommended for full threshold sweeps.
makeGraph = true; //set to true to make a graph of the table at the end of analysis. Set to false when running parameter sweeps
sortCoord = false; // set to true to sort coordinates from left to right rather than the order they were marked in 
printStats = true; // print all good EB areas
printIntensityValues = false; // print all good EB mean intensities
createMaskTF = true;

//Manual selection options
onlyUseUserMark = false; // All selections are made from the user mark
ifBadSelectFromUserMark = false; // If no good quality EB selection is found, center selection around the user coordinates
ResearcherManualOutlineBad = false; // after checking slices, the Bad selections are manually evaulated 
ResearcherManualOutlineBadGood = false; // After checking slices  Good and Bad selections can be manually changed
ManualSelectAll = false; // Every selection, even the slice comparison ones can be manually changed
if (catchBadQManualSegment == true) {
Dialog.create("Manual selection options");
Dialog.addCheckbox("During analysis, all selections are only selected from the user's coordinates", onlyUseUserMark);
Dialog.addCheckbox("After analysis, If no good quality EB selection is found, the selection is centered around the user's coordinates", ifBadSelectFromUserMark);
Dialog.addCheckbox("After analysis, if the EB's selection is of Good or Bad quality, then the user has the option to create a selection", ResearcherManualOutlineBadGood);
Dialog.addCheckbox("After analysis, if the EB's selection is of Bad quality, then the user has the option to create a selection", ResearcherManualOutlineBad);
Dialog.addCheckbox("During analysis every selection can be manually set", ManualSelectAll);
Dialog.show();
//Manual selection options
onlyUseUserMark = Dialog.getCheckbox(); // All selections are made from the user mark
ifBadSelectFromUserMark = Dialog.getCheckbox(); // If no good quality EB selection is found, center selection around the user coordinates
ResearcherManualOutlineBadGood = Dialog.getCheckbox(); // After checking slices Good and Bad selections can be manually changed
ResearcherManualOutlineBad = Dialog.getCheckbox();// After checking slices only Bad selections can be manually changed
ManualSelectAll = Dialog.getCheckbox(); // Every selection, even the slice comparison ones can be manually changed
}

//Only change threshSweep to true if running a parameter sweep
threshSweep = false; // set this to true when running a threshold parameter sweep
if (batchMode == true) {
  setBatchMode(true);
}
 /*  //delete or comment out to run parameter sweeps. 
paraSweepArr = newArray();// comment and uncomment lines to run parameter sweeps
//paraSweepArr = Array.concat(paraSweepArr,"Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum","Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen");
//paraSweepArr = Array.concat(paraSweepArr,"Intermodes","Li","MaxEntropy","Mean","Minimum","Moments","Shanbhag");
//paraSweepArr = Array.concat(paraSweepArr,"Shanbhag");
//paraSweepArr = Array.concat(paraSweepArr, 0.17, 0.51, 0.85, 1.2, 1.53); //linewidth
//paraSweepArr = Array.concat(paraSweepArr,0.34,0.5,0.85,1,2);//mincircsize
paraSweepArr = Array.concat(paraSweepArr,1,3,5,7,9);//slices
saveImgOri = saveImg; // saveImg will change but saveImgOri will be kept as the original
for (j = 0; j < paraSweepArr.length; j++) { // If not running parameter sweep remember to comment out the close bracket for this for loop at the end of the main
  //lineWidth_um = paraSweepArr[j];
  //minCirc_um = paraSweepArr[j];
  zVol_um = paraSweepArr[j];
  //thresholdMethod = paraSweepArr[j];
    
  File.makeDirectory(saveImgOri+paraSweepArr[j]);
  saveImg = saveImgOri +paraSweepArr[j]+ File.separator;
   //*/
if (postProccRes == true) { // create two directories for small and big EB boxes
  saveImgO = saveImg;
  bigImgFileName = "bigImgs"; // String to name the file that holds the big images  
  bigImgDir = saveImg + bigImgFileName;
  File.makeDirectory(bigImgDir);
  EBfileName = "smallImgs"; // String to name the file that holds the small images 
  saveImg = saveImgO + EBfileName;
  File.makeDirectory(saveImg);
}
bigImgName = "Bg"; // saveTitleB = "_" + imgName + bigImgName + EBcount; // Name of EB
denoteSmallStack = "smallStack"; // smallStackName = tablename + denoteSmallStack;
denoteBigStack = "bigStack"; // bigStackName = tablename + denoteBigStack;
markNumLabel = "EB"; //string is added to every indivudual EB in the folder marked"EB"# 
fileList = getFileList(imgDir); // Get the list of files from the chosen directory
IJ.redirectErrorMessages(); // "Causes next image opening error to be redirected to the Log window and prevents the macro from being aborted"
if (tableLabels == true) {
  tablename = createTableWLabels(fileList[0], letter); // Table is created with first files name before the inputed character "letter". Functions are at the bottom. returns table name
} else {
  tablename = createTable(fileList[0], letter); //
}
for (ii = 0; ii < fileList.length; ii++) { // For loop runs through all files/ images in chosen directory/ dir
  if (batchMode == true && is("Batch Mode") == 0) { // later in the loop, if batch mode is exited it has to be put back to true
    setBatchMode(true);
  }
  if (endsWith(fileList[ii], ".tif")) {
    open(imgDir + File.separator + fileList[ii]); // open image in file list if it is a tif
  }
  Stack.setChannel(channel);
  originalImg = getImageID(); // ID of tiff image
  getPixelSize(unit, pixelWidth, pixelHeight); // Pixel width, height and depth in microns can be found by going to image -> properties (Ctrl+Shift+P)               
  minAreaSizeum = (pixelWidth * pixelWidth) * (minAreaPixels + 1); // Minimum area size for an EB is set to pixelWidth's um^2 (1 pixel). Set to 2 to account for the difference in decimal places. Equation (pixelWidth*pixelWidth) *((desired # of minimum pixels) +1)    
  lineLength = boxmicrons / 2;
  lineLengthpixel = ((boxmicrons / 2) / pixelWidth); // line length of DTA lines
  lineWidthpixel = lineWidth_um / pixelWidth; // line width in microns is converted to an amount of pixels
  minCircPixels = minCirc_um / pixelWidth; // Min circle size in microns is converted to an amount of pixels
  imgName = File.getNameWithoutExtension(imgDir + File.separator + fileList[ii]);
  // imgName = replace(imgName, "_", ""); //shorten name if needed
  row = Table.size; // variable row is used for the created Table
  coorArray = newArray(); // Array will hold images overlay coordinates and their slices
  if (gray == true) { // If users decided to change images to grayscale
    run("Grays");
  }
  if (choice == false) { // Choice is  by user
    if (batchMode == true) {
      setBatchMode("exit and display");
    }
    setTool("multipoint");
    waitForUser("Mark all EBs (click) and add to ROI (ctrl+T) then press okay");
    //roiManager("Add");
    if (roiManager("count") > 0) {
    run("From ROI Manager");
    coorArray = ROItoArr(); // function puts overlay coordinates to ROI then puts them into an array thats returned as coorArray.
    }
  }
  if (choice == true) {
    coorArray = ROItoArr(); // function puts overlay coordinates to ROI then puts them into an array thats returned as coorArray.
  }
  if (sortCoord == true) {
    coorArray = sortCoorArray(coorArray); //uncomment to sort coordinates from left to right rather than by the order they were marked in
  }
  EBcount = 0; // accumulator variable to count EBs in each image
  // Array.print(coorArray);
  for (i = 0; i < coorArray.length; i = i + 3) { // For loop will run as many times as there were overlay selections in the image. +3 for X Y and Z
    if (batchMode == true && is("Batch Mode") == 0) { // 
      setBatchMode(true);
    }
    makePoint(coorArray[i], coorArray[i + 1]); // Setting coordinates from array
    Stack.setSlice(coorArray[i + 2]);
    userX = coorArray[i];
    userY = coorArray[i + 1];
    pointSlice = coorArray[i + 2]; // Slice with coordinate
    EBcount++;
    Table.set("Label", row, imgName); // EBs label is the images title
    Table.set("Mark", row, EBcount); // EB number in image
    Table.set("User X", row, userX); // Users X and Y overlay selection will be saved in the table
    Table.set("User Y", row, userY);
    Table.set("User Slice", row, pointSlice);
    Table.update;
    selectImage(originalImg);
    if (onlyUseUserMark == true) {
      quality = "G"; // G: EB is Good
      Table.set("Quality", row, quality); 
      newImages = useUserSlice();
      savedCopy = newImages[0];
      copyUsed = newImages[1];
    }else {
		userSliceRadius = firstCircle(userX, userY, pointSlice);
	    quality = checkSlices(userX, userY, pointSlice, userSliceRadius);
	    centX = Table.get("Center X", row); // Center X and Y overlay selection will be saved in the table
	    centY = Table.get("Center Y", row);
    //if (quality == "G") {
    //	quality = checkDuplicates(centX,centY,EBcount);
    //}
    Table.set("Quality", row, quality); 
    if (ifBadSelectFromUserMark == true && quality == "B") {
	  	Table.set("Center X", row, userX); // Users X and Y overlay selection will be saved in the table
	    Table.set("Center Y", row, userY);
	    Table.set("Slice", row, pointSlice);
	  	selectImage(originalImg);
	  	Stack.setSlice(pointSlice);
	  	makeSquare(userX, userY, originalImg, boxmicrons);	
    }else{
	    goodSlice = Table.get("Slice", row);
	    selectImage(originalImg);
	    Stack.setSlice(goodSlice);
	    makeSquare(centX, centY, originalImg, boxmicrons);	
    }
    run("Duplicate...", " "); // two copies of the EB box are created
    savedCopy = getImageID(); // Saved copy gets saved
    run("Duplicate...", " ");
    copyUsed = getImageID(); // copyUsed is manipulated for analyses
    newAreaInfo = newArray();
    newAreaInfo = getArea(savedCopy, copyUsed);
    Table.set("EB Threshold", row, newAreaInfo[0]); // derivatively calculated threshold is saved
    if (Table.get("watershed", row) == 1) {
        newAreaInfo = newArray();
    	newAreaInfo = watershed(copyUsed, savedCopy); //  AreaResults = Array.concat(AreaResults, mean, area, highcirc, cornerSelected, centerSelected, centerMSelected);
    }
    Table.set("Mean", row, newAreaInfo[1]); // mean pixel intensity of EB selection is saved
    Table.set("Area", row, newAreaInfo[2]); // area of EB selection is saved
    Table.set("circularity", row, newAreaInfo[3]);
    if (newAreaInfo[3] > circularity) {
      Table.set("Above min Circularity", row, "True");
    } else {
      Table.set("Above min Circularity", row, "False");
    }
    Table.set("corner selected", row, newAreaInfo[4]);
    Table.set("centroid inside 1st circle", row, newAreaInfo[5]);
    Table.set("COM inside 1st circle", row, newAreaInfo[6]);
    if (newAreaInfo[3] < circularity || newAreaInfo[2] < minAreaSizeum || newAreaInfo[4] == true || newAreaInfo[5] == false || newAreaInfo[6] == false) { //Check if anything indicates the quality is bad
      quality = "B";
    } else {
      quality = "G";
    }
    if (quality == "G") {
    	quality = checkDuplicates(centX,centY,EBcount);
    }
    Table.set("Quality" , row, quality);
    Table.update;
    selectImage(savedCopy);
    List.setMeasurements;
    max = getValue("Max"); // Highest Intensity Pixel
    if (max == saturated) {
      quality = "S";
    }
    }
    if (batchMode == false && quality != "S") {
      circul = Table.get("circularity", row);
      setBatchMode("exit and display");
      run("To Selection");
      waitForUser("Check table and move images around to decide in next window if EB is acceptable \nCircularity: " + circul);
      chooseEB = getBoolean("Is EB acceptable?");
      if (chooseEB == true) { // If EB is acceptable
        quality = "G"; // G: EB is Good
      } else {
        quality = "B"; // B: EB is Bad and should not be used in statistical analysis
      }
      setBatchMode(true);
    }
    if (postProccRes == true ) {
      bigTitle = makeBigBox(originalImg, bigBoxmicrons);
      Bigimg = getImageID();
      saveTitleB = quality + bigTitle; // Name of EB
      pathB = bigImgDir + File.separator + saveTitleB;
      //print(pathB);
      saveAs("Tiff", pathB);
      selectImage(Bigimg);
      close(); // big images saved and closed
    }
    Table.set("Quality", row, quality); // Table will show whether the EB was acceptable or not
    Table.update;
    path = saveImg + File.separator + quality + "_" + imgName + markNumLabel + EBcount; //Image file name 
    selectImage(savedCopy);
    saveAs("tiff", path); // EBbox will be saved as a tiff file
    // showMessageWithCancel("Image saved using path and title: "+path);
    roiManager("reset");
    selectImage(savedCopy);
    close();
    selectImage(copyUsed);
    close(); // close windows
    row = row + 1;
    selectImage(originalImg);
    resetMinAndMax();
    close("\\Others");
  } // for loop of all coordinates in an image
  selectImage(originalImg);
  close("*");
} // for loop processing all images in the chosen image folder 
if (postProccRes == true && row >2) {
  postProcc(saveImg, bigImgDir);
  GoodEBAreas = printGoodQuality();
  Table.save(saveImgO + tablename + ".csv"); // Save results table
} else {
  GoodEBAreas = printGoodQuality();
  Table.save(saveImg + tablename + ".csv"); // Save results table
}
if (batchMode == true && postProccRes == false) {
  setBatchMode("exit and display");
}
graphArea(); // Function gets areas from table and makes a bar graph
if (printStats == true) {
Array.print(GoodEBAreas);
saveAs("Text", saveImg + "Log.txt");
}
//}//Parameter sweep for loop close bracket 


/* Makes a square with size in microns centered around x y on image
   Called in main script, function makeBigBox. Returns size of box in pixels*/
function makeSquare(x, y, image, boxSize) {
  selectImage(image);
  getPixelSize(unit, pixelWidth, pixelHeight); // Pixel width, height and depth in microns can be found by going to image -> properties (Ctrl+Shift+P)
  BoxHeightWidth = boxSize / pixelWidth; // The size of the rectangle in microns divided by pixelWidth (Ctrl+Shift+P)
  BoxHeightWidth = round(BoxHeightWidth); // Round to the nearest whole pixel size
  halfRec = BoxHeightWidth / 2;
  makeRectangle(x - halfRec, y - halfRec, BoxHeightWidth, BoxHeightWidth);
  return BoxHeightWidth; // Returns size of box in pixels
}
/* Makes a circle with radius in microns centered around x y on image
  Called in functions qualityCheck, makeDerivativeCircle and checkSlices. Returns radius of circle in pixels */
function makeSmallCirc(x, y, image, sCircSize) { // Makes a circle with size in microns centered arund x y on image
  selectImage(image);
  getPixelSize(unit, pixelWidth, pixelHeight); // Pixel width, height and depth in microns can be found by going to image -> properties (Ctrl+Shift+P)
  radius = sCircSize / pixelWidth; // The size of the radius in microns divided by pixelWidth (Ctrl+Shift+P)
  radius = round(radius); // Round to the nearest whole pixel size
  cHeightWidth = radius * 2;
  makeOval(x - radius, y - radius, cHeightWidth, cHeightWidth);
  return radius; // Returns radius of circle in pixels
}

/*  Function takes all the coordinates in the image and returns them sorted based on the x array coordinates so EBs are processed left to right
   Function can be uncommented in the main script to incorporate. */
function sortCoorArray(cooArray) {
  coo2Array = newArray();
  x = newArray();
  y = newArray();
  z = newArray();
  for (i = 0; i < cooArray.length; i = i + 3) {
    x = Array.concat(x, cooArray[i]);
    y = Array.concat(y, cooArray[i + 1]);
    z = Array.concat(z, cooArray[i + 2]);
  }
  Array.sort(x, y, z); //sort the three arrays according to array x
  for (i = 0; i < x.length; i++) {
    coo2Array = Array.concat(coo2Array, x[i], y[i], z[i]);
  }
  return coo2Array;
}

/* Used to get the overlay coordinates to the ROI then into an array of x,y,z
  called in the main script and returns the array of coordinates */
function ROItoArr() {
    run("To ROI Manager"); // The predefined coordinate overlay selection is added to the ROI manager
    run("Select All");
    roiManager("measure");
    // Create arrays to store values
    xValues = newArray(nResults);
    yValues = newArray(nResults);
    sliceValues = newArray(nResults);
    
    // Extract values from results table
    for (i = 0; i < nResults; i++) {
        xValues[i] = getResult("XM", i);
        yValues[i] = getResult("YM", i);
        sliceValues[i] = getResult("Slice", i);
    }
    
    // Create a combined array in the format X1,Y1,Slice1,X2,Y2,Slice2,...
    combinedArray = newArray(nResults * 3);
    for (i = 0; i < nResults; i++) {
        combinedArray[i*3] = xValues[i];
        combinedArray[i*3 + 1] = yValues[i];
        combinedArray[i*3 + 2] = sliceValues[i];
    }
    selectWindow("Results");
    run("Close");
 // Array.print(combinedArray);
  roiManager("reset"); // ROI is emptied
  return combinedArray; // Returns array with all XYZ coordinates of point selection overlay from image
} 

/*From the center of the EBbox run DTA w/ user input line length and populate table with line values.
  Calls on function derivative. Called inside function getArea. Returns calculated threshold*/
function DerivativeThresh(EBbox) {
  selectImage(EBbox);
  width = getWidth(); // gets width of image2
  height = getHeight(); // gets height of image2
  midWidth = width / 2;
  midHeight = height / 2;
  threshArr = newArray(); // array to save Intensity values
  intResultArr = newArray();
  x = midHeight;
  y = midHeight;
  for (i = 0; i < 8; i++) { // for 8 lines
    point2x = (x - lineLengthpixel);
    point2y = y;
    angle = 0.785 * i; // 45 degree rotation times i
    newX = x + ((point2x - x) * (Math.cos(angle)) - ((point2y - y)) * (Math.sin(angle)));
    newY = y + ((point2x - x) * (Math.sin(angle)) + ((point2y - y)) * (Math.cos(angle))); // makes lines in a circle
    makeLine(midHeight, midHeight, newX, newY, lineWidthpixel);
    // run("Add Selection...");
    // roiManager("add")
    Line = getProfile();
    Intensity = derivative(Line); // derivative(inputLineHere) function returns intensity from derivative analyses finding most negtaive slope
    if (Intensity != 0) { // if a derivative is not found then a 0 is returned.
      threshArr = Array.concat(threshArr, Intensity); // only use non 0 values for the determined threshold
    }
    intResultArr = Array.concat(intResultArr, Intensity);
    // run("To Selection");
  }
  // Array.print(threshArr);
  // waitForUser("check lines");
  Array.getStatistics(threshArr, threshMin, max, avgThresh, stdDev); // getting mean value
  Table.set("topLeftIntensity", row, intResultArr[1]); // set intensities in table
  Table.set("topIntensity", row, intResultArr[2]);
  Table.set("topRightIntensity", row, intResultArr[3]);
  Table.set("rightIntensity", row, intResultArr[4]);
  Table.set("botRightIntensity", row, intResultArr[5]);
  Table.set("botIntensity", row, intResultArr[6]);
  Table.set("botLeftIntensity", row, intResultArr[7]);
  Table.set("leftIntensity", row, intResultArr[0]);
  return avgThresh; // Non 0 values returned from function derivative are averaged and returned to be used as the threshold to determine area
  selectImage(EBbox);
  run("Select None");
}

/*saved copy is image, copy used for measurments is image2. Function applys derivative threshold analyses to EB box
  Called in main script. Calls function DerivativeThresh and qualityCheck. Returns results of area measurements and quality check*/
function getArea(image, image2) {
  selectImage(image2); // EB box
  width = getWidth(); // gets width of image2
  height = getHeight(); // gets height of image2
  midWidth = width / 2;
  midHeight = height / 2;
  items = roiManager("count"); // items = 0
  if (gaussianSigma > 0) {
  	run("Gaussian Blur...", "sigma="+ gaussianSigma);
  	selectImage(image);
  	run("Gaussian Blur...", "sigma="+ gaussianSigma);
  	selectImage(image2);
  }
  if (threshSweep == false) {
    avgThresh = DerivativeThresh(image2);
    setThreshold(avgThresh, upperBoundThresh); // With an average intensity, a average threshold can be inputted to find area, mean gray value and measurments of EB
  } else {
    setAutoThreshold(thresholdMethod + " dark no-reset");
    getThreshold(avgThresh, upper);
  }
  Qual = Table.getString("Quality", row);
  //print(useUserS +","+ ResearcherManualOutlineBad +","+ Qual);
  runManual = false;
  if ( ResearcherManualOutlineBad == true && Qual == "B"   ) {
    	runManual = true;
    }
  if ( ResearcherManualOutlineBadGood == true && Qual == "B" || Qual == "G" ) {
    	runManual = true;
    }
  if ( ManualSelectAll == true  ) {
    	runManual = true;
    }  
  if ( runManual == true  ) {
  	setBatchMode("exit and display");
  	run("Create Selection");
  	run("Convex Hull");
  	setTool("polygon");
    waitForUser("Create selection by having points surround the area");
    Table.set("watershed", row, false);
    resetThreshold;
    selectImage(image);
    resetThreshold;
    selectImage(image2);
  }else {
  //waitForUser("Set threshold");
  // print("EB Threshold: " + avgThresh);
  selectImage(image2); // image is EBbox size of microns, finding centered EB is done before measuring
  run("Create Selection"); // objects in threshold range will be selected
    if (is("area") == false) {
      centerInt = getPixel(midWidth, midHeight);
      setThreshold(centerInt, upperBoundThresh);
      run("Create Selection");
    }
  }
  roiManager("add");
  index = roiManager("index");
  type = selectionType;
  centeredEB = false;
  roiManager("select", items); // select first thing in ROI
  List.setMeasurements; // getting the measurments from the ROI manager selection
  lowArea = getValue("Area");
  if (type == 9) { // selection type 9 means its a composite selection
    roiManager("select", items);
    roiManager("split"); // splitting the selection
    distanceArray = newArray();
    for (i = roiManager("count") - 1; i > items - 1; i--) { // loop will go through all items in ROI manager
      roiManager("select", i);
      if (Roi.contains(midHeight, midWidth) == true) { // EB is centered in image
        List.setMeasurements; // getting the measurments from the ROI manager selection
        area = getValue("Area");
        centeredEB = true;
        if (area <= lowArea) { // The whole selection will contain the center cooridnates so selection with smallest area is found
          lowArea = area;
          index = roiManager("index"); // Index is EB
        }
      }
    }
    if (centeredEB == true) { // If the ROI had a selection at the center of the EB box
      roiManager("select", index);
      List.setMeasurements; // getting the measurments from the ROI manager selection
      area = getValue("Area");
      mean = getValue("Mean");
      highcirc = getValue("Circ. ");
      selectImage(image2);
      roiManager("select", index);
      run("Add Selection...");
      selectImage(image);
      roiManager("select", index);
      run("Add Selection..."); // overlay selection of EB is added to saved copy
      // run("Select None");
    }
    if (centeredEB == false) {
      // print("in measurment, EB is not centered"); //EB should be centered in image
      area = 0;
      mean = 0;
      highcirc = 0;
    }
  } else { // if not a selection type 9.
    List.setMeasurements;
    area = getValue("Area");
    mean = getValue("Mean");
    highcirc = getValue("Circ. ");
    selectImage(image2);
    roiManager("select", items);
    run("Add Selection...");
    selectImage(image);
    roiManager("select", items);
    run("Add Selection..."); // overlay selection of EB is added to saved copy
    // run("Select None");
  }
  AreaResults = newArray();
  AreaResults = Array.concat(AreaResults, avgThresh, mean, area, highcirc);
  qualResults = newArray();
  qualResults = qualityCheck();
  cornerSelected = qualResults[0];
  centerSelected = qualResults[1];
  centerMSelected = qualResults[2];
  // print("check selection" +cornerSelected+","+centerSelected+","+centerMSelected);
  // showMessageWithCancel("check selection" +cornerSelected+","+centerSelected+","+centerMSelected);
  setThreshold(avgThresh, upperBoundThresh); // EBbox image will be threshold when made so watershed code can be run on EBs close to objects
  AreaResults = Array.concat(AreaResults, cornerSelected, centerSelected, centerMSelected);
  //Array.print(AreaResults);
  return AreaResults; // Returns Array with info of selection
}
/* Checks if center of selection in image qualCheck is inside the radius of the 1st circle. Also checks if corner is selected
   Calls function makeSmallCirc. Called in functions getArea and watershed. Returns results as a list of 1s and 0s or True and False. */
function qualityCheck() {
  qualCheck = getImageID();
  qualResults = newArray();
  Roi.getContainedPoints(xpointsA, ypointsA); //coordinates for area selection
  XC = getValue("X");
  YC = getValue("Y"); //getting the centroid
  XM = getValue("XM");
  YM = getValue("YM"); //getting the Center of mass
  XC = round(XC / pixelWidth);
  YC = round(YC / pixelWidth);
  XM = round(XM / pixelWidth);
  YM = round(YM / pixelWidth);
  roiManager("reset");
  run("Select None");
  // print(XC+","+YC+","+XM+","+YM);
  userCircSize = Table.get("1st Radius um", row);
  if (userCircSize < minCirc_um) {
    userCircSize = minCirc_um;
  }
  makeSmallCirc(midWidth, midHeight, qualCheck, userCircSize);
  //run("Add Selection...");//uncomment to see circles made with the selection
  Roi.getContainedPoints(xpoints, ypoints); // coordinates for circle selection
  roiManager("reset");
  run("Select None");
  // Array.print(xpoints);
  // Array.print(ypoints);
  centerSelected = false;
  centerMSelected = false;
  cornerSelected = false;
  for (i = 0; i < xpointsA.length; i++) {
    if (xpointsA[i] == 1 || xpointsA[i] == width - 1 || ypointsA[i] == 1 || ypointsA[i] == width - 1) { // Checking if a corner is selected
      cornerSelected = true;
    }
  }
  for (i = 0; i < xpoints.length; i++) {
    if (xpoints[i] == XC && ypoints[i] == YC) { //Checking if the centroid is in the selected pixels
      centerSelected = true;
    }
    if (xpoints[i] == XM && ypoints[i] == YM) { //Checking if the center of mass is in the selected pixels
      centerMSelected = true;
    }
  }
  qualResults = Array.concat(qualResults, cornerSelected, centerSelected, centerMSelected);
  return qualResults;
}
/*Clear outside of selection made before the function was called. Highest intensity pixel is found inside circle.
  Called in function checkSlices. Height and width of HIP are retuned to check for saturated area */
function findHIP() {
  run("Clear Outside");
  List.setMeasurements;
  max = getValue("Max"); // Highest Intensity Pixel
  setThreshold(max, upperBoundThresh);
  run("Create Selection");
  getSelectionBounds(x, y, width, height);
  // waitForUser;
  midW = width / 2;
  midH = height / 2;
  x = x + midW;
  y = y + midH;
  PixelArray = newArray();
  PixelArray = Array.concat(PixelArray, x, y, width, height);
  return PixelArray; // Pixel coordinates of center of HIP selection and selection size
}
/* function returns intensity of point on line with first greatest decrease in intensity
   Called in function DerivativeThresh*/
function derivative(line) {
  line = getProfile(); // calculate derivative at each point (want the most negative slope)
  getPixelSize(unit, pixelWidth, pixelHeight);
  bigSlope = 0; // variable for saving the most negative slope
  derIntensity = 0; // intensity at big slope
  dist = pixelWidth; // distance between points
  returned = false;
  for (i = 1; i < line.length - 1; i++) { // calculates slope for point i (rise/run)
    der = (line[i + 1] - line[i - 1]) / (2 * dist); // derivative analysis of line
    if (der < bigSlope) { // overrides previous bigSlope if newest calc der is larger
      bigSlope = der;
      derIntensity = line[i];
    }
    if (bigSlope < 0 && der > 0 || der == 0) { // only return most negative derivative when current derivative is postive or 0
      return derIntensity; // Will return intensity value at point of greatest intensity change in selected line
      returned = true
      // print(derIntensity);
    }
  }
  if (returned == false) { // if previous if condition was not met, derIntensity will still return as most negative slope
    return derIntensity; // Will most likely return 0 as previous return statement was never called
  }
}
/* function returns distance of point on line with first greatest decrease in intensity
   Called in function makeDerivativeCircle */
function dropOff(line) {
  line = getProfile(); // calculate derivative at each point (want the most negative slope)
  getPixelSize(unit, pixelWidth, pixelHeight);
  bigSlope = 0; // variable for saving the most negative slope
  derIntensity = 0; // intensity at big slope
  distance = 0;
  dist = pixelWidth; // distance between points
  returned = false;
  for (i = 1; i < line.length - 1; i++) { // calculates slope for point i (rise/run)
    der = (line[i + 1] - line[i - 1]) / (2 * dist); // derivative analysis of line
    if (der < bigSlope) { // overrides previous bigSlope if newest calc der is larger
      bigSlope = der;
      derIntensity = line[i];
      distance = i;
    }
    if (bigSlope < 0 && der > 0 || der == 0) { // only return most negative derivative when current derivative is postive or 0
      // print(distance);
      return distance; // returns distance at greatest drop in intensity of line
      returned = true
    }
  }
  if (returned == false) { // if previous if condition was not met, derIntensity will still return as most negative slope
    return distance;
  }
}
/* Makes circle using average distance from most negative derivative distance around x,y.
   Calls function dropOff. Called in functions firstCircle, checkSlices. Returns array circle*/
function makeDerivativeCircle(x, y, img2) {
  selectImage(img2);
  width = getWidth(); // gets width of image2
  height = getHeight(); // gets height of image2
  midWidth = width / 2;
  midHeight = height / 2;
  distArr = newArray(); // array to save Intensity values
  for (i = 0; i < 8; i++) { // For loop makes 8 lines
    point2x = (x - lineLengthpixel);
    point2y = y;
    angle = 0.785 * i;
    newX = x + ((point2x - x) * (Math.cos(angle)) - ((point2y - y)) * (Math.sin(angle)));
    newY = y + ((point2x - x) * (Math.sin(angle)) + ((point2y - y)) * (Math.cos(angle))); // Makes 8 lines in a circle from center x, y
    makeLine(x, y, newX, newY, lineWidthpixel);
    // run("Add Selection...");
    Line = getProfile();
    Intensity = dropOff(Line); // derivative(inputLineHere) function returns intensity from derivative analyses finding most negtaive slope
    if (Intensity != 0) { // If distance is not 0 then use it to calculate the radius
      distArr = Array.concat(distArr, Intensity);
    }
    // run("To Selection");
    // showMessageWithCancel("Capture lines");
  }
  Array.getStatistics(distArr, distMin, max, mean, stdDev);
  // print(distMin + " -min , max- " + max + " , mean- " + mean + " , stdDev-  " + stdDev);

  //if (maxCircPixels <= mean) {
  //  mean = maxCircPixels;
  // }
  circDiameter = (mean * 2); // mean is the radius of the circle
  makeOval((x - mean), (y - mean), circDiameter, circDiameter);
  circle = newArray();
  radiusum = mean * pixelWidth;
  // print(" radius  " + radius+" mean " +mean);
  // waitForUser;
  if (radiusum < minCirc_um) { // Checks if small/default circle is needed
    makeSmallCirc(x, y, dupe, minCirc_um);
    radiusum = minCirc_um;
    circCheck = false;
  } else {
    circCheck = true;
  }
  List.setMeasurements();
  cMean = getValue("Mean");
  circle = Array.concat(circle, circCheck, cMean, radiusum); // details about the circle
  return circle; // Returns array with the details about the derivative circle made
}
/* Finds first HIP and fills table on 1st circle details.
   Calls function makeDerivativeCircle. Called in main script. Returns X Y of HIP*/
function firstCircle(x, y, Slice) {
  selectImage(originalImg);
  Stack.setSlice(Slice);
  run("Select None"); // Nothing selected
  run("Duplicate...", " "); // Duplicate whole image to find HIP
  dupe = getImageID();
  circle = newArray();
  circle = makeDerivativeCircle(x, y, dupe); // function returns details about the circle in an array
  // makeSquare(x, y, dupe, boxmicrons);
  //waitForUser("1st circle made on user slice");
  if (circle[0] == 1) { // Derivative circle is made
    Table.set("1st Circle", row, "1C");
  }
  if (circle[0] == 0) { // Default/ small circle was made
    Table.set("1st Circle", row, "1SC");
  }
  Table.set("1st Radius um", row, circle[2]);
  selectImage(dupe);
  // waitForUser;
  run("Close");
  selectImage(originalImg);
  return circle[2]; // returns the radius of the circle
}
/* Checks all slices to find the brightest good area selection. Sets table with area details from each slice
   Calls makeSmallCirc,findHIP, makeSquare, getArea, watershed. Called in main script and returns EB quality.*/
function checkSlices(userX, userY, pointSlice, userRadius) {
  selectImage(originalImg);
  getVoxelSize(pixelWidth, height, depth, unit); // The voxel depth of an image is in microns and can be found by going to image -> properties (Ctrl+Shift+P)
  zSliceF = floor(zVol_um / depth); // User input of Z slices in microns divided by the depth is floored to the nearest whole number
  if (zSliceF % 2 == 0) { // This ensures only an odd number of slices are checked
    zSliceF = zSliceF - 1;
  }
  zSliceFlank = zSliceF / 2; // zSliceFlank: Variable found in function highestMeanSlice, is the amount of Z slices that will be checked above and below initial Z slice from user selection for estimated highest intensity of EB
  zSliceFlank = floor(zSliceFlank); // amount of z slices checked around originalImg chosen slice
  leftMin = pointSlice - zSliceFlank;
  rightMax = pointSlice + zSliceFlank;
  Stack.getDimensions(width, height, channels, slices, frames);
  leftMin = Math.constrain(leftMin, 1, slices); // math.constrain is able to keep the value of leftMin between 1 and total amount of slices
  rightMax = Math.constrain(rightMax, 1, slices);
  highSlice = pointSlice;
  highX = userX;
  highY = userY;
  bestQuality = "B";
  highMean = 0;
  highestMean = 0;
  watershe = false;
  for (i = 0; i < zSliceF; i++) { // For loop goes through all compared slices
    selectImage(originalImg);
    currSlice = leftMin + i;
    currSlice = Math.constrain(currSlice, leftMin, rightMax);
    Stack.setSlice(currSlice);
    run("Select None"); // Nothing selected
    run("Duplicate...", " "); // Duplicate whole image to find HIP of slice
    dupe = getImageID();
    highSliPix = newArray();
    makeSmallCirc(userX, userY, dupe, userRadius);
    //waitForUser("Circle made on slice:" +currSlice+ " r:"+ userRadius);
    highSliPix = findHIP();
    slicex = highSliPix[0];
    slicey = highSliPix[1];
    width = highSliPix[2];
    height = highSliPix[3];
    width = round(width);
    height - round(height);
    //makeSquare(userX, userY, dupe, boxmicrons/2);
    //waitForUser("Circle made on slice:" +currSlice+ " r:"+ userRadius);
    selectImage(dupe);
    close(); // Close image of slice used to find HIP
    selectImage(originalImg);
    run("Select None"); // Nothing selected
    Table.set("x" + currSlice, row, slicex);
    Table.set("y" + currSlice, row, slicey);
    Table.update;
    makeSquare(slicex, slicey, originalImg, boxmicrons);
    run("Duplicate...", " ");
    slicebox1 = getImageID(); // First copy will be saved with selection
    run("Duplicate...", " "); // two copies of the EB box are created
    slicebox2 = getImageID(); // Second copy is manipulated for analyses
    areaInfo = getArea(slicebox1, slicebox2);
    sliceThreshold = areaInfo[0];
    sliceMean = areaInfo[1];
    sliceArea = areaInfo[2];
    sliceCircularity = areaInfo[3];
    cornerSelected = areaInfo[4];
    centerSelected = areaInfo[5];
    centerMSelected = areaInfo[6];
    if (sliceCircularity < circularity + Wbias || cornerSelected == true || centerMSelected == false || centerSelected == false) { //check if anything indicates the quality is bad to run watershed
      sliceWatershed = newArray();
      sliceWatershed = watershed(slicebox2, slicebox1);
      sliceMean = sliceWatershed[1];
      sliceArea = sliceWatershed[2];
      sliceCircularity = sliceWatershed[3];
      cornerSelected = sliceWatershed[4];
      centerSelected = sliceWatershed[5];
      centerMSelected = sliceWatershed[6];
      watershe = true;
    } else {
      watershe = false;
    }
    if (sliceCircularity < circularity || sliceArea < minAreaSizeum || cornerSelected == true || centerMSelected == false || centerSelected == false) { //Check if anything indicates the quality is bad
      quality = "B";
    } else {
      quality = "G";
    }
    Table.set("Quality" + currSlice, row, quality);
    Table.set("Area" + currSlice, row, sliceArea);
    if (width > 1 || height > 1) {
      stringMean = d2s(sliceMean, 0);
      stringHeight = toString(width);
      stringWidth = toString(height);
      sliceString = stringMean + "W" + stringWidth + "H" + stringHeight;
      Table.set("Intensity" + currSlice, row, sliceString);
    } else {
      Table.set("Intensity" + currSlice, row, sliceMean);
    }
    Table.update;
    // waitForUser("Selection made on slice:" +currSlice+ " Area:"+ sliceArea + " Intensity:" + sliceMean);
    selectImage(slicebox1);
    close();
    selectImage(slicebox2);
    close(); // close windows
    if (quality == "G" && sliceMean > highMean) { //If the quality is good the best highest mean intensity selection is found
      highMean = sliceMean;
      bestQuality = quality;
      bestX = slicex;
      bestY = slicey;
      bestSlice = currSlice;
      bestThresh = sliceThreshold;
      bestMean = sliceMean;
      bestArea = sliceArea;
      bestCircularity = sliceCircularity;
      bestCornerSel = cornerSelected;
      bestCenterSel = centerSelected;
      bestCenterMSel = centerMSelected;
      bestWatershed = watershe;
    }
    if (sliceMean > highestMean) { // highest mean intensity selection regardless of quality is saved as the default slice
      //	print("found a good slice"+row);
      highestMean = sliceMean;
      highSlice = currSlice;
      bQuality = quality;
      bX = slicex;
      bY = slicey;
      bSlice = currSlice;
      bThresh = sliceThreshold;
      bMean = sliceMean;
      bArea = sliceArea;
      bCircularity = sliceCircularity;
      bCornerSel = cornerSelected;
      bCenterSel = centerSelected;
      bCenterMSel = centerMSelected;
      bWatershed = watershe;
    }
  }
  if (bestQuality == "G") {
    Table.set("Center X", row, bestX); // Highest intensity pixels are saved as the center of the EB
    Table.set("Center Y", row, bestY);
    Table.set("Slice", row, bestSlice);
    Table.set("watershed", row, bestWatershed);
    Table.set("EB Threshold", row, bestThresh); // derivatively calculated threshold is saved
    Table.set("Mean", row, bestMean); // mean pixel intensity of EB selection is saved
    Table.set("Area", row, bestArea); // area of EB selection is saved
    Table.set("circularity", row, bestCircularity);
    if (bestCircularity > circularity) {
      Table.set("Above min Circularity", row, "True");
    } else {
      Table.set("Above min Circularity", row, "False");
    }
    Table.set("corner selected", row, bestCornerSel);
    Table.set("centroid inside 1st circle", row, bestCenterSel);
    Table.set("COM inside 1st circle", row, bestCenterMSel);
    Table.update;
    return bestQuality;
  } else {
    Table.set("Center X", row, bX); // Highest intensity pixels are saved as the center of the EB
    Table.set("Center Y", row, bY);
    Table.set("Slice", row, bSlice);
    Table.set("watershed", row, bWatershed);
    Table.set("EB Threshold", row, bThresh); // derivatively calculated threshold is saved
    Table.set("Mean", row, bMean); // mean pixel intensity of EB selection is saved
    Table.set("Area", row, bArea); // area of EB selection is saved
    Table.set("circularity", row, bCircularity);
    if (bCircularity > circularity) {
      Table.set("Above min Circularity", row, "True");
    } else {
      Table.set("Above min Circularity", row, "False");
    }
    Table.set("corner selected", row, bCornerSel);
    Table.set("centroid inside 1st circle", row, bCenterSel);
    Table.set("COM inside 1st circle", row, bCenterMSel);
    Table.update;
    return bQuality;
  }

}

/*If no good slice is found then the user's chosen slice's selection is shown and the results are set in the table
  Calls makeSquare, getArea, watershed. Called in main and returns array with image IDs*/
function useUserSlice() {
  imageReturn = newArray();
  areaInfo = newArray();
  uX = Table.get("User X", row); // Users X and Y overlay selection will be saved in the table
  uY = Table.get("User Y", row);
  userSlice = Table.get("User Slice", row);
  //uX = Table.get("x" + userSlice, row); // Users X and Y overlay selection will be saved in the table
  //uY = Table.get("y" + userSlice, row);
  selectImage(originalImg);
  Stack.setSlice(userSlice);
  makeSquare(uX, uY, originalImg, boxmicrons);
  run("Duplicate...", " "); // two copies of the EB box are created
  slicebox1 = getImageID(); // First copy will be used to save the selection and EB
  run("Duplicate...", " "); // 
  slicebox2 = getImageID(); // Second copy is manipulated for analyses
  areaInfo = getArea(slicebox1, slicebox2);
  sliceThreshold = areaInfo[0];
  sliceMean = areaInfo[1];
  sliceArea = areaInfo[2];
  sliceCircularity = areaInfo[3];
  cornerSelected = areaInfo[4];
  centerSelected = areaInfo[5];
  centerMSelected = areaInfo[6];
  if (sliceCircularity < circularity + Wbias || cornerSelected == true || centerMSelected == false || centerSelected == false) {
    sliceWatershed = newArray();
    sliceWatershed = watershed(slicebox2, slicebox1);
    sliceMean = sliceWatershed[1];
    sliceArea = sliceWatershed[2];
    sliceCircularity = sliceWatershed[3];
    cornerSelected = sliceWatershed[4];
    centerSelected = sliceWatershed[5];
    centerMSelected = sliceWatershed[6];
    watershe = true;
  } else {
    watershe = false;
  }
  if (sliceArea < minAreaSizeum || sliceCircularity < circularity || cornerSelected == true || centerMSelected == false || centerSelected == false) {
    quality = "B";
    imageReturn = Array.concat(imageReturn, slicebox1, slicebox2);
  } else {
    quality = "G";
    imageReturn = Array.concat(imageReturn, slicebox1, slicebox2);
  }
  Table.set("Quality", row, quality);
  Table.set("Center X", row, uX); // Highest intensity pixels are saved as the center of the EB
  Table.set("Center Y", row, uY);
  Table.set("Slice", row, userSlice);
  Table.set("watershed", row, watershe);
  Table.set("EB Threshold", row, sliceThreshold); // derivatively calculated threshold is saved
  Table.set("Mean", row, sliceMean); // mean pixel intensity of EB selection is saved
  Table.set("Area", row, sliceArea); // area of EB selection is saved
  Table.set("circularity", row, sliceCircularity);
    if (sliceCircularity > circularity) {
      Table.set("Above min Circularity", row, "True");
    } else {
      Table.set("Above min Circularity", row, "False");
    }
  Table.set("corner selected", row, cornerSelected);
  Table.set("centroid inside 1st circle", row, centerSelected);
  Table.set("COM inside 1st circle", row, centerMSelected);
  Table.update;
  return imageReturn;
}
// Create plot with area on the x axis and number of EBs on the y axis, only using good quality EBs from the table. Prints amount of good EBs
// Function called at the end of the main script
function graphArea() {
  Areas = newArray();
  Areas = Table.getColumn("Area");
  //  Array.print(Areas);
  Array.getStatistics(Areas, min, max, mean, stdDev);
  maxArea = round(max + 1); // X-axis datapoint's max value
  // print(maxArea);
  qualit = newArray();
  qualit = Table.getColumn("Quality");
  avgInt = newArray();
  avgInt = Table.getColumn("Mean");
  goodIntensity = newArray();
  areaArr = newArray();
  graphArr = newArray();
  totalCount = 0;//count good EBs
  saturatedCount = 0;
  notCircularEnough = 0;
  WatershedCounts = 0;
  watershedArray = Table.getColumn("watershed");
  circulBoolArray = Table.getColumn("Above min Circularity");
  cornerSelArray = Table.getColumn("corner selected");
  centroidArray = Table.getColumn("centroid inside 1st circle");
  comArray = Table.getColumn("COM inside 1st circle");
  for (i = 0; i < qualit.length; i++) {
  if (qualit[i] == "S") {
  	saturatedCount++;
  	}
  if (watershedArray[i]== 1) {
  	WatershedCounts++;
    }
  if (circulBoolArray[i]=="False" && cornerSelArray[i] == 0 && centroidArray[i] == 1 && comArray[i] == 1) {
  	notCircularEnough++;
    } 	
  }
  for (i = 0; i < maxArea; i++) { // The area sizes on the X-axis
    count = 0;
    for (ii = 0; ii < Areas.length; ii++) { // Checks all EBs
      aValue = floor(Areas[ii]);
      if (aValue == i && qualit[ii] == "G") { // If area is equal to an area on the X-axis and is good, then the data point is saved and used in calculating average area.
        // print(count);
        count = count + 1;
        totalCount = totalCount + 1;
        graphArr = Array.concat(graphArr, Areas[ii]);
        goodIntensity = Array.concat(goodIntensity, avgInt[ii]);
      }
    }
    areaArr = Array.concat(areaArr, count);
  }
  Array.getStatistics(goodIntensity, min, max, intMean, stdDev);
  Array.getStatistics(graphArr, min, max, areaMean, stdDev);
  if (makeGraph == true) {
    Plot.create("EBs Area", "EB Area", "EB", areaArr);
    Plot.setStyle(0, "black,none,1.0,Separated Bars");
    Plot.setXYLabels("EB area in microns^2", "EBs");
    Plot.setFormatFlags("11000000000011");
    Plot.setLimits( - 1, 20, NaN, NaN);
  }
  //Array.print(graphArr);
  if (threshSweep == true) {
    print(thresholdMethod + "    " + totalCount + "      " + areaMean + "       " + intMean);
  } else {
    print("FIJITAcc: " + totalCount + " / "+ (Table.size-1) +" Average area: " + areaMean + " Average intensity: " + intMean);
  }
  if (printStats == true) {
  	print("Saturated: " + saturatedCount + "  Isolated with low circularity: " + notCircularEnough + "  Total watersheds: " + WatershedCounts); 
  }

  //print( mean + " "+ totalCount);
}
/*Prints area of EBs with good quality and fills the good area and good mean intensity part of the table
  Called in main script  */
function printGoodQuality(){
	GoodEBAreas = newArray();
	GoodEBMeans = newArray();
	for (i = 0; i < Table.size; i++) {
    finalQuality = Table.getString("Quality", i);
    	if (finalQuality == "G") {
    	goodArea = Table.get("Area", i);
    	Table.set("Good Areas", i, goodArea);
    	goodMeanInten = Table.get("Mean", i);
    	Table.set("Good Mean Intensity", i, goodMeanInten);
    	GoodEBAreas = Array.concat(GoodEBAreas,goodArea);
    	GoodEBMeans = Array.concat(GoodEBMeans, goodMeanInten);
    	}
	}
	Table.update;
	if (printIntensityValues == true) {
		Array.print(GoodEBMeans);
	}
	return GoodEBAreas;
}
/*Makes big image for post processing
  Calls function makeSquare */
function makeBigBox(originalImg, bigBoxSize) {
  bigCentX = Table.get("Center X", row); // Users X and Y overlay selection will be saved in the table
  bigCentY = Table.get("Center Y", row);
  EBSliceB = Table.get("Slice", row);
  boxP = bigBoxSize / pixelWidth; // getting the pixel size of the big box
  selectImage(originalImg);
  W = getWidth();
  H = getHeight();
  Stack.setSlice(EBSliceB); // The box is made on the highest slice
  makeSquare(bigCentX, bigCentY, originalImg, boxmicrons);
  run("Enhance Contrast", "saturated=0.35"); // contrast of image is enhanced by 0.35/35%
  remainderW = W - bigCentX;
  remainderH = H - bigCentY;
  if (remainderW < boxP || remainderH < boxP || bigCentX < boxP || bigCentY < boxP) { // checking if there is enough space to place a complete box around the EB
    setSize = newArray();
    setSize = Array.concat(setSize, remainderW, remainderH, bigCentX, bigCentY); //
    Array.getStatistics(setSize, minPix, max, mean, stdDev); // minPix becomes how big the box size is
    minSize = minPix * pixelWidth;
    if (minSize < boxmicrons) { // The minimum size of the big box is the EB box size.
      minSize = boxmicrons;
    }
    makeSquare(bigCentX, bigCentY, originalImg, minSize);
  } else {
    makeSquare(bigCentX, bigCentY, originalImg, bigBoxSize);
  }
  run("Duplicate...", " "); // The big box is made and duplicated
  //Bigimg = getImageID();
  saveTitleB = "_" + imgName + bigImgName + EBcount; // Name of EB
  return saveTitleB;
}
/*From the two image files, opens all images and turns them into two stacks. Grabs overlay from first file then places it at the center of the second files images
  Called in function postProcc. Returns ID of both stacks*/
function openOvImgs(saveImg, bigImgDir) {
  roiManager("reset");
  returnArray = newArray();
  if (is("Batch Mode") == false) {
    setBatchMode(true);
  }
  filelist = getFileList(saveImg);
  for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".tif")) {
      open(saveImg + File.separator + filelist[i]); // Open all tiff images in saveImg directory
      width = getWidth();
      height = getHeight();
      midWidth = width / 2;
      midHeight = height / 2;
      EBThreshv = getPixel(midHeight, midHeight);
      setMinAndMax(0, EBThreshv);
    }
  }
  smallStackName = tablename + denoteSmallStack;
  run("Images to Stack", "name=[" + smallStackName + "] use"); // stack of EB boxes made from open images
  smallStack = getImageID();
  if (is("Batch Mode") == true) {
    setBatchMode("exit and display");
  }
  run("To ROI Manager");
  DXArr = newArray();
  DYArr = newArray();
  for (i = 0; i < roiManager("count"); i++) { // For loop finds the X and Y distance of the middle of the image to the center of the EB selection
    roiManager("select", i);
    width = getWidth();
    height = getHeight();
    // print(width);
    midWidth = width / 2;
    midHeight = height / 2;
    Roi.getBounds(x, y, Rwidth, Rheight);
    // print(x+","+y);
    DX = midWidth - x;
    DY = midHeight - y;
    DXArr = Array.concat(DXArr, DX); // Arrays hold distance that overlays will have to be moved by in big box EB images.
    DYArr = Array.concat(DYArr, DY);
  }
  run("Select None");
  if (is("Batch Mode") == false) {
    setBatchMode(true);
  }
  filelistBig = getFileList(bigImgDir);
  for (i = 0; i < lengthOf(filelistBig); i++) {
    if (endsWith(filelistBig[i], ".tif")) {
      open(bigImgDir + File.separator + filelistBig[i]); // Open all images in directory that end with .tif
      width = getWidth();
      height = getHeight();
      midWidth = width / 2;
      midHeight = height / 2;
      EBThreshv = getPixel(midHeight, midHeight);
      setMinAndMax(0, EBThreshv); // try to adjust brightness contrast
      // run("Apply LUT");
    }
  }
  // waitForUser;
  wait(300);
  bigStackName = tablename + denoteBigStack;
  run("Images to Stack", "name=[" + bigStackName + "] use"); // big box stack made from opened images
  if (is("Batch Mode") == true) {
    setBatchMode("exit and display");
  }
  bigStack = getImageID();
  width = getWidth();
  height = getHeight();
  midWidth = (width / 2);
  midHeight = (height / 2);
  run("From ROI Manager");
  for (i = 0; i < roiManager("count"); i++) {
    roiManager("select", i);
    Overlay.moveSelection(i, midWidth - DXArr[i], midHeight - DYArr[i]); // overlay moved in each big box image
  }
  run("Select None");
  Stack.setSlice(1);
  returnArray = Array.concat(returnArray, smallStack, bigStack);
  return returnArray;
}
/*Function post process allows the user to flip an EBs quality in the EB stacks
  Calls on function openOvImgs. Called in main script. */
function postProcc(saveImg, bigImgDir) {
  imgArr = openOvImgs(saveImg, bigImgDir); // function openOvImgs opens the small and big images
  filelist = getFileList(saveImg);
  filelistBig = getFileList(bigImgDir);
  smallStack = imgArr[0];
  bigStack = imgArr[1];
  contAnalysis = true;
  while (contAnalysis == true) { // while loop allows user to flip EB quality endlessly
    if (skipPostProQuestions == true) {
      mislabl = false;
    } else {
      waitForUser("Scroll through slices in either stack and find EBs that have quality mislabeled. \nOnce one is found press OK \nIf none are found, press OK and then No on the next screen");
      mislabl = getBoolean("Press Yes once a mislabled EB is found (If there are no mislabeled EBs, press No)");
    }
    if (mislabl == true) { // If user finds mislabeled EB
      sliceChange = getSliceNumber();
      ROInum = sliceChange - 1;
      selectImage(smallStack);
      Stack.setSlice(sliceChange);
      imgNameQO = getInfo("slice.label"); // get title of slice chosen by user
      run("Duplicate...", " ");
      imgNameQO2 = getTitle();
      imgNameQ = imgNameQO;
      if (imgNameQ.contains("G_") == true) {
        Qindex = indexOf(imgNameQ, "G_");
        firstLetter = "G"; // name will be title of image title before letter
      }
      if (imgNameQ.contains("B_") == true) {
        Qindex = indexOf(imgNameQ, "B_");
        firstLetter = "B"; // name will be title of image title before letter
      }
      EBnum = indexOf(imgNameQ, markNumLabel);
      restOfFilenameO = substring(imgNameQ, Qindex);
      inputlength = lengthOf(markNumLabel);
      lastNumber = substring(imgNameQ, EBnum + inputlength); // compenents of name: quality/number saved
      finalIndex = indexOf(restOfFilenameO, markNumLabel + lastNumber);
      nameInTable = substring(restOfFilenameO, 2, finalIndex);
      // print(imgNameQ + "," + restOfFilename + "," + firstLetter + "," + lastNumber);
      // print(imgNameQ);
      Tablesize = Table.size;
      if (tableLabels == true) {
        start = 1; // rows start at 1
        Tablesize = Tablesize - 1;
      } else {
        start = 0; // rows start at 0
      }
      for (i = start; i < Table.size; i++) {
        EBLabelTemp = Table.getString("Label", i);
        //   print(EBLabelTemp);
        EBnumTemp = Table.get("Mark", i);
        if (EBLabelTemp == nameInTable && EBnumTemp == lastNumber) {
          opQual = Table.getString("Quality", i);
          if (opQual == "G") {
            opQual = "B";
          } else {
            opQual = "G";
          }
          Table.set("Quality", i, opQual);
          Table.update;
        }
      }
      if (startsWith(restOfFilenameO, "B")) { // flips the quality in the image name
        restOfFilename = substring(restOfFilenameO, 1);
        newNameR = "G" + restOfFilename;
      }
      if (startsWith(restOfFilenameO, "G")) {
        restOfFilename = substring(restOfFilenameO, 1);
        newNameR = "B" + restOfFilename;
      }
      name2 = saveImg + File.separator + newNameR;
      selectImage(imgNameQO2);
      // rename(newNameR);
      roiManager("select", ROInum);
      Overlay.addSelection;
      saveAs("Tiff", name2 + ".tif"); // image is saved with new name
      for (i = 0; i < filelist.length; i++) {
        //print(filelist[i] + "," + restOfFilenameO);
        if (filelist[i] == restOfFilenameO + ".tif") {
          path = saveImg + File.separator + filelist[i];
          // print(path);
          w2 = File.delete(path);
          if (w2 == 0) {
            print("Could not delete: " + filelist[i]);
          }
        }
      }
      // print(w2+","+imgNameQ+"     ,"+name1+"  ,  "+name2);
      close();
      selectImage(bigStack);
      Stack.setSlice(sliceChange);
      imgNameBig = getInfo("slice.label");
      run("Duplicate...", " ");
      imgNameBigO = getTitle();
      if (imgNameBig.contains("G_") == true) {
        Qindex = indexOf(imgNameBig, "G_");
        nameinTableB = substring(imgNameBig, Qindex);
        restOfFilenameBig = substring(imgNameBig, Qindex + 1);
        newNameB = "B" + restOfFilenameBig;
      }
      if (imgNameBig.contains("B_") == true) {
        Qindex = indexOf(imgNameBig, "B_");
        nameinTableB = substring(imgNameBig, Qindex);
        restOfFilenameBig = substring(imgNameBig, Qindex + 1);
        newNameB = "G" + restOfFilenameBig;
      }
      name2B = bigImgDir + File.separator + newNameB;
      selectImage(imgNameBigO);
      Overlay.remove;
      width = getWidth();
      height = getHeight();
      midWidth = (width / 2);
      midHeight = (height / 2);
      rename(newNameB);
      saveAs("Tiff", name2B + ".tif"); // image is saved with new name
      for (i = 0; i < filelistBig.length; i++) {
        //print(filelistBig[i]+","+nameinTableB);
        if (filelistBig[i] == nameinTableB + ".tif") {
          pathB = bigImgDir + File.separator + filelistBig[i];
          //	print(pathB);
          w4 = File.delete(pathB);
          if (w4 == 0) {
            print("Could not delete: " + filelistBig[i]);
          }
        }
      }
      // print(imgNameBig+"     ,"+w4+","+name1B+"  ,  "+name2B);
      close();
    } else {
      close("*");
      roiManager("reset");
      // waitForUser;
      imgArr = openOvImgs(saveImg, bigImgDir);
      smallStack = imgArr[0];
      bigStack = imgArr[1];

	  if (createMaskTF == true) {
		maskInPostProcc(bigImgDir, smallStack );	
	  }

      selectImage(bigStack);
      saveAs("Tiff", bigImgDir + File.separator + tablename + denoteBigStack);
      selectImage(smallStack);
      // run("From ROI Manager");
      saveAs("Tiff", saveImg + File.separator + tablename + denoteSmallStack);
      return;
    }
  }
}



// ImageJ Macro to convert Overlay selections to Binary Masks
// Works with multi-slice TIFF stacks
function maskInPostProcc(fileName, smallStack ) {
	maskImgFileName = "MaskedImgs"; // String to name the file that holds the big images  
	maskImgDir = fileName + File.separator +  maskImgFileName;
	File.makeDirectory(maskImgDir);
selectImage(smallStack);
imgID = getImageID();
imgTitle = getTitle();
getDimensions(width, height, channels, slices, frames);

// Remove file extension and add _BW suffix
baseName = File.getNameWithoutExtension(imgTitle);
newTitle = baseName + "_BW.tif";

// Convert Overlay to ROI Manager
//run("To ROI Manager");

// Get number of ROIs
roiCount = roiManager("count");

if (roiCount == 0) {
    run("To ROI Manager");
    //exit("No ROIs found in overlay!");
}

// Create a new binary stack with same dimensions
newImage(newTitle, "8-bit black", width, height, slices);
maskID = getImageID();

// Process each slice
selectImage(imgID);
for (i = 0; i < roiCount; i++) {
    // Select ROI in ROI Manager
    roiManager("select", i);
    
    // Get the slice position for this ROI
    Roi.getPosition(channel, slice, frame);
    
    // If no position info, ROI might be on current slice
    if (slice == 0) {
        slice = getSliceNumber();
    }
    
    // Switch to mask image and correct slice
    selectImage(maskID);
    setSlice(slice);
    
    // Select the same ROI and fill it with white
    roiManager("select", i);
    setForegroundColor(255, 255, 255);
    run("Fill", "slice");
}

// Clean up
selectImage(maskID);
run("Select None");

// Save the binary mask stack

savePath = maskImgDir + File.separator +  newTitle;
saveAs("Tiff", savePath);

// Show completion message
//print("Binary mask saved as: " + savePath);
//print("Processed " + roiCount + " ROIs across " + slices + " slices");

// Optional: Close ROI Manager
roiManager("reset");
}




/* Watershed seperation is done in EB box and center object is measured and returned (sometimes seperation fails).
   Calls on function qualCheck. Called in userAnalysis and autoAnalysis. Returns array with area values*/
function watershed(image, image2) {
  selectImage(image2);
  //run("Duplicate...", " ");
  //qualCheck = getImageID(); // copy for selection analysis
  width = getWidth();
  height = getHeight();
  midWidth = width / 2;
  midHeight = height / 2;
  selectImage(image);
  getThreshold(lower, upper);
  if (lower == -1) {
  	thresh = Table.get("EB Threshold", row);
  	setThreshold(thresh, upperBoundThresh);
  }
  run("Create Selection");
  run("Clear Outside"); // clear background around selection
  setOption("BlackBackground", false);
  run("Convert to Mask"); // image needs to be binary for watershed
  run("8-bit");
  wait(100); // This is a bandaid to a recurring watershed error where it couldn't detect that the image was 8-bit. Remove/ lower number with caution
  run("Watershed");
  items = roiManager("count");
  run("Create Selection");
  List.setMeasurements; // getting the measurments from the ROI manager selection
  lowArea = getValue("Area"); // area of the whole selection is used to find EB selection with smallest area
  index = 0;
  bIndex = 0;
  minDistance = width;
  type = selectionType;
  roiManager("add");
  centeredEB = false;
  if (type == 9) { // selection type 9 means its a composite selection (can be split)
    roiManager("select", items);
    roiManager("split"); // splitting the composite selection
    roiManager("select", items);
    distanceArray = newArray();
    for (i = roiManager("count") - 1; i > items - 1; i--) { // loop will go through all items in ROI manager
      roiManager("select", i);
      List.setMeasurements; // getting the measurments from the ROI manager selection
      if (selectionContains(midHeight, midWidth) == true) {
        area = getValue("Area");
        centeredEB = true;
        if (area < lowArea) { // finding the ROI selection with the least amount of area and in the center
          lowArea = area;
          index = roiManager("index"); // Index is EB
        }
      }
      if (centeredEB == false) {
        selectionX = getValue("X");
        selectionY = getValue("Y");
        selectionX = round(selectionX / pixelWidth);
        selectionY = round(selectionY / pixelWidth);
        distance = sqrt((selectionX - midWidth) ^ 2 + (selectionY - midHeight) ^ 2);
        if (distance < minDistance || distance == 0) { // finding the ROI selection with the least amount of distance to the center
          minDistance = distance;
          bIndex = roiManager("index");
          //print(distance);
        }
      }
    }
    if (centeredEB == true) {
      selectImage(image2);
      roiManager("select", index);
      List.setMeasurements; // getting the measurments from the ROI manager selection
      highcirc = getValue("Circ. ");
      area = getValue("Area");
      mean = getValue("Mean");
      selectImage(image2);
      roiManager("select", index);
      run("Remove Overlay"); // remove old overlay
      roiManager("select", index);
      run("Add Selection..."); // add new overlay
      // run("Select None");
    }
    if (centeredEB == false) {
      selectImage(image2);
      roiManager("select", bIndex);
      List.setMeasurements; // getting the measurments from the ROI manager selection
      highcirc = getValue("Circ. ");
      area = getValue("Area");
      mean = getValue("Mean");
      selectImage(image2);
      roiManager("select", index);
      run("Remove Overlay"); // remove old overlay
      roiManager("select", index);
      run("Add Selection..."); // add new overlay
      // run("Select None");
    }
  } else { // if not a selection type 9.
    selectImage(image2);
    overlayI = getInfo("overlay");
    if (overlayI.contains("1") == false) {
      // run("Auto Threshold");
      run("Convert to Mask");
      run("Create Selection");
      run("Add Selection...");
    }
    run("To ROI Manager");
    selectImage(image2);
    roiManager("Select", 0);
    List.setMeasurements;
    highcirc = getValue("Circ.");
    area = getValue("Area");
    mean = getValue("Mean");
    run("Remove Overlay"); // remove old overlay
    roiManager("select", 0);
    run("Add Selection..."); // adding the overlay
  }
  qualResults = newArray();
  qualResults = qualityCheck();
  cornerSelected = qualResults[0];
  centerSelected = qualResults[1];
  centerMSelected = qualResults[2];
  // print("checkselection" +cornerSelected+","+centerSelected+","+centerMSelected);
  //  showMessageWithCancel("checkselection" +cornerSelected+","+centerSelected);
  AreaResults = newArray();
  AreaResults = Array.concat(AreaResults,0, mean, area, highcirc, cornerSelected, centerSelected, centerMSelected);
  return AreaResults; // Returns circularity of selection
}
/* Checks for duplicate EB coordinates in an image
   Called in main script. Returns quality */
function checkDuplicates(centX,centY,EBcount){
	//print(EBcount);
	quality = "G";
	bottomofTable = Table.size; 
	X = Table.getColumn("Center X");
	Y = Table.getColumn("Center Y");
	Q = Table.getColumn("Quality");
	for (i = 2; i < EBcount+1; i++) {
		currRow1 = bottomofTable - i;
		//print(EBcount +" in for loop " + currRow1);	
		if (Q[currRow1] == "G") {
			X2 = X[currRow1];
			Y2 = Y[currRow1];
		    //print(centX +" , "+centY );
			//print(X2 +" , "+Y2 );
			if (centX == X2 && centY == Y2) {
				quality = "B";
				//print(quality);
			}
		}
	}
	return quality;
}
/* First image in file is used to make table name. Table variable names are set.
   Function called in main script. Returns table's name to save .csv file.*/
function createTable(image, letter) {
  open(imgDir + File.separator + image); // marked image is opened
  imgName = getTitle(); // Title of image will be used when saving EBs in files
  Stack.getDimensions(width, height, channels, slices, frames); // get the variable slices
  if (imgName.contains(letter) == true) {
    num = indexOf(imgName, letter);
    imgName = substring(imgName, 0, num); // name will be title of image title before letter
  }
  tableTitle = imgName;
  row = 0;
  Table.create(tableTitle); // new results table is made and will be saved automatically at the end of the analyses
  Table.set("Label", row, 0); // EBs label is the images title
  Table.set("Mark", row, 0); // Determined from marking order in image
  Table.set("Quality", row, 0); // Table will show whether the EB was acceptable or not
  Table.set("Area", row, 0);
  Table.set("Good Areas", row,0);
  Table.set("Mean", row, 0);
  Table.set("Good Mean Intensity", row,0);
  Table.set("EB Threshold", row, 0); // Calculated threshold is saved
  Table.set("watershed", row, 0); // True if watershed function was run, false otherwise.
  Table.set("circularity", row, 0);
  Table.set("Center X", row, 0); // Highest intensity pixel and the center of the EB
  Table.set("Center Y", row, 0);
  Table.set("Slice", row, 0); // Most in focus slice
  Table.set("User X", row, 0); // Users X and Y overlay selection will be saved in the table
  Table.set("User Y", row, 0);
  Table.set("User Slice", row, 0);
  Table.set("1st Circle", row, 0);
  Table.set("1st Radius um", row, 0);
  Table.set("Slices", row, "Slices");
  for (i = 1; i < slices + 1; i++) { // Set all slices in the table as a column
   	Table.set("Quality" + i, row, 0);
    Table.set("Area" + i, row, 0);
    Table.set("Intensity" + i, row, 0);
    Table.set("x" + i, row, 0);
    Table.set("y" + i, row, 0);
  }
  Table.set("topLeftIntensity", row, 0);
  Table.set("topIntensity", row, 0);
  Table.set("topRightIntensity", row, 0);
  Table.set("rightIntensity", row, 0);
  Table.set("botRightIntensity", row, 0);
  Table.set("botIntensity", row, 0);
  Table.set("botLeftIntensity", row, 0);
  Table.set("leftIntensity", row, 0);
  Table.set("Above min Circularity", row, 0);
  Table.set("corner selected", row, 0);
  Table.set("centroid inside 1st circle", row, 0);
  Table.set("COM inside 1st circle", row, 0);
  Table.deleteRows(0, 1); // First row was populated with 0s as a placeholder, this deletes those.
  Table.update;
  close();
  return imgName; // Returns the name of the table. Created from title of first image in file directory
}
/* First image in file is used to make table name. Table variable names are set with their titles
   Function called in main script. Returns table's name to save .csv file.*/
function createTableWLabels(image, letter) {
  open(imgDir + File.separator + image); // marked image is opened
  imgName = getTitle(); // Title of image will be used when saving EBs in files
  Stack.getDimensions(width, height, channels, slices, frames); // get the variable slices
  if (imgName.contains(letter) == true) {
    num = indexOf(imgName, letter);
    imgName = substring(imgName, 0, num); // name will be title of image title before letter
  }
  tableTitle = imgName;
  row = 0;
  Table.create(tableTitle); // new results table is made and will be saved automatically at the end of the analyses
  Table.set("Label", row, "Label"); // EBs label is the images title
  Table.set("Mark", row, "Mark"); // Determined from marking order in image
  Table.set("Quality", row, "Quality"); // Table will show whether the EB was acceptable or not
  Table.set("Area", row, "Area");
  Table.set("Good Areas", row,"Good Areas");
  Table.set("Mean", row, "Mean");
  Table.set("Good Mean Intensity", row,"Good Mean Intensity");
  Table.set("EB Threshold", row, "EB Threshold"); // Calculated threshold is saved  
  Table.set("watershed", row, "watershed"); // True if watershed function was run, false otherwise.
  Table.set("circularity", row, "circularity");
  Table.set("Center X", row, "Center X"); // Highest intensity pixel and the center of the EB
  Table.set("Center Y", row, "Center Y");
  Table.set("Slice", row, "Slice"); // Most in focus slice
  Table.set("User X", row, "User X"); // Users X and Y overlay selection will be saved in the table
  Table.set("User Y", row, "User Y");
  Table.set("User Slice", row, "User Slice");
  Table.set("1st Circle", row, "1st Circle");
  Table.set("1st Radius um", row, "1st Radius um");
  Table.set("Slices", row, "Slices");
  for (i = 1; i < slices + 1; i++) { // Set all slices in the table as a column
  	Table.set("Quality"+i, row, "Quality"+i);
    Table.set("Area" + i, row, "Area" + i);
    Table.set("Intensity" + i, row, "Intensity" + i);
    Table.set("x" + i, row, "x" + i);
    Table.set("y" + i, row, "y" + i);
  }
  Table.set("topLeftIntensity", row, "topLeftIntensity");
  Table.set("topIntensity", row, "topIntensity");
  Table.set("topRightIntensity", row, "topRightIntensity");
  Table.set("rightIntensity", row, "rightIntensity");
  Table.set("botRightIntensity", row, "botRightIntensity");
  Table.set("botIntensity", row, "botIntensity");
  Table.set("botLeftIntensity", row, "botLeftIntensity");
  Table.set("leftIntensity", row, "leftIntensity");
  Table.set("Above min Circularity", row, "Above min Circularity");
  Table.set("corner selected", row, "corner selected");
  Table.set("centroid inside 1st circle", row, "centroid in 1st circle");
  Table.set("COM inside 1st circle", row, "COM in 1st circle");
  Table.update;
  close();
  return imgName; // Returns the name of the table. Created from title of first image in file directory
}

