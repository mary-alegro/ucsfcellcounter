

import ij.IJ;
import ij.ImageJ;
import ij.ImageListener;
import ij.ImagePlus;
import ij.gui.ImageCanvas;
import ij.gui.ImageWindow;
import ij.gui.Overlay;
import ij.gui.PointRoi;
import ij.gui.Toolbar;
import ij.io.OpenDialog;
import ij.plugin.filter.PlugInFilter;
import ij.process.ImageProcessor;
import ij.process.StackConverter;

import java.awt.Color;
import java.awt.event.AdjustmentEvent;
import java.awt.event.AdjustmentListener;
import java.awt.event.FocusEvent;
import java.awt.event.FocusListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.io.File;
import java.io.IOException;
import java.util.LinkedList;
import java.util.List;

import javax.swing.JMenuItem;
import javax.swing.JPopupMenu;

import matlabcontrol.MatlabInvocationException;
import matlabcontrol.MatlabProxy;
import matlabcontrol.MatlabProxyFactory;
import matlabcontrol.MatlabProxyFactoryOptions;
import matlabcontrol.extensions.MatlabNumericArray;
import matlabcontrol.extensions.MatlabTypeConverter;


public class UCSF_Cell_Counter implements FocusListener, AdjustmentListener, ImageListener, MouseListener, PlugInFilter {
	
	protected ImagePlus image;
	private CellCounterJFrame dgCount;
	private CellCount count;
	private JPopupMenu jpopUp;

	// image property members
	private int width;
	private int height;
	private int origWidth;
	private int origHeight;

	boolean firstRun = true;
	private boolean isInsideImage = false;
	
	//Segmentation method
	private int segMethod = Consts.DL; 

	
    private List<LinkedList<Point>> listPoints = new LinkedList<LinkedList<Point>>();
    private List<PointRoi> listROIs = new LinkedList<PointRoi>();

	private Overlay overlay;
	private LinkedList<Point> pointsRed;
	private LinkedList<Point> pointsGreen;
	private LinkedList<Point> pointsOver;
	private LinkedList<Point> pointsNuclei;
	
	//ROI colors and size
	private Color[] currentROIColor = Consts.ROI_COLORS_DEFAULT;

	
	//for mouse listeners
	private int selectedROI = Consts.ROI_RED;
	private Point selectedPoint;

	// plugin parameters
	public double value;
	public String name;
	
	//MATLAB stuff
	private MatlabProxyFactoryOptions options;
	private MatlabProxyFactory factory;
	private MatlabProxy proxy;
	private MatlabTypeConverter mProcessor;
	private double [][] matlabR;
	private double [][] matlabG;
	private double [][] matlabB;
	
	@Override
	public int setup(String arg, ImagePlus imp) {

		if (arg.equals("about")) {
			showAbout();
			return DONE;
		}
		
		this.image = imp;
		this.count = new CellCount();
		this.pointsRed = new LinkedList<Point>();
		this.pointsGreen = new LinkedList<Point>();
		this.pointsOver = new LinkedList<Point>();
		this.pointsNuclei = new LinkedList<Point>();
		
		Toolbar.getInstance().addTool("Cell counter - C0a0L18f8L818f");
		Toolbar.getInstance().setTool(20);
		
		this.width = imp.getProcessor().getWidth();
		this.height = imp.getProcessor().getHeight();
		this.origWidth = this.width;
		this.origHeight = this.height;
		
		this.count = new CellCount();

		try{
			options = new MatlabProxyFactoryOptions.Builder().setUsePreviouslyControlledSession(true).build(); 
			factory = new MatlabProxyFactory(options);
		}catch(Exception e){
			IJ.error("Could not open Matlab interface.");
			e.printStackTrace();
			return -1;
		}

		return DOES_RGB;
	}
	
	
	@Override
	public void run(ImageProcessor ip) {
		
		this.count.reset();
		initDialogWindow();
		initPopUpColorMenu();
		this.dgCount.setCounters(this.count);
		this.dgCount.setVisible(true);
		
		initPointROIs();
		installListeners();

	}
	
	public void process(){
		
		if(!firstRun){
			this.count.reset();	
			this.listPoints.get(Consts.ROI_RED).clear();
			this.listPoints.get(Consts.ROI_GREEN).clear();
			this.listPoints.get(Consts.ROI_OVERLAP).clear();
			this.listPoints.get(Consts.ROI_NUCLEI).clear();
			updateCountDialog();
		}
		
		//this.run(null);
		this.process(null);
	}


	// Select processing method depending on image type
	public void process(ImageProcessor ip) {
		int type = this.image.getType();

		if(ip == null){
			//this.image = WindowManager.getCurrentImage();
			ip = this.image.getProcessor();
		}
		
		// get width and height	
		this.width = ip.getWidth();
		this.height = ip.getHeight();
		this.origWidth = this.width;
		this.origHeight = this.height;

		//init matlab interface
		try{
			if(this.proxy != null){
				this.proxy.disconnect();
			}
			this.proxy = factory.getProxy();
			this.mProcessor = new MatlabTypeConverter(proxy);
		}catch(Exception e){
			IJ.error("Could not open Matlab interface.");
			e.printStackTrace();
		}
		
		
		//initDialogWindow();

		//If its too big, reduces its size
		ip.setInterpolationMethod(ImageProcessor.BICUBIC);
		ImageProcessor sProc = ip;
		
		if(segMethod == Consts.SVM){
			int lSide = sProc.getWidth();
			int sSide = sProc.getHeight();
			int maxSize = 1000;
			boolean widthLgst = true;
			if(lSide < sSide){
				lSide = sProc.getHeight();
				sSide = sProc.getWidth();
				widthLgst = false;
			}
			//ImagePlus sImage = null;
			if(lSide > maxSize){
				if(widthLgst){
					sProc = ip.resize(maxSize);
				}else{
					int newSize = Math.round((sSide*maxSize)/lSide);
					sProc = ip.resize(newSize,maxSize);
				}
				
				//sImage = new ImagePlus("Resized Image", sProc);
				this.width = sProc.getWidth();
				this.height = sProc.getHeight();		
			}

		}else{
			if(this.width >= 1000){
				int newW = (int)Math.round(this.width*0.25);
				sProc = ip.resize(newW);	
				this.width = sProc.getWidth();
				this.height = sProc.getHeight();
			}
		}
		
		
		this.matlabR = new double[this.height][this.width];
		this.matlabG = new double[this.height][this.width];
		this.matlabB = new double[this.height][this.width];
		
		if (type == ImagePlus.COLOR_RGB){
	
			int pixels[] = (int [])sProc.getPixels();
			//create matrices for R,G and B channels and send to matlab 
			for (int y=0; y < height; y++) {
				for (int x=0; x < width; x++) {
					int idx = x + y * width;
					
					int r = (pixels[idx] & 0xff0000) >> 16;
					int g = (pixels[idx] & 0x00ff00) >> 8;
					int b = (pixels[idx] & 0x0000ff);
					
					this.matlabR[y][x] = r;
					this.matlabG[y][x] = g;
					this.matlabB[y][x] = b;
				}
			}
		
			//run matlab code
			try{
				
				//clear unecessary variable in matlab workspace
				proxy.eval("clear all;");
				
				//export matrices
				this.mProcessor.setNumericArray("R", new MatlabNumericArray(this.matlabR, null));
				this.mProcessor.setNumericArray("G", new MatlabNumericArray(this.matlabG, null));
				this.mProcessor.setNumericArray("B", new MatlabNumericArray(this.matlabB, null));
				
				//run segmentation
				IJ.showProgress(0.1);
				
				String cmd = "";
				switch(this.segMethod){
					case Consts.SVM:
						System.out.println("Segmenting using SVM");
						cmd =  "[mask,R2,G2,B2,cX,cY,types] = test_svm2(R,G,B," +
								this.origHeight + "," + this.origWidth + ",0);";
						break;
					case Consts.DL: 
						int wsize = Consts.WINDOW_SIZE[this.dgCount.getWindowSizeSel()];
						System.out.println("Segmenting using DL");
						cmd = "[mask,R2,G2,B2,cX,cY,types] = test_DL1(R,G,B,"
								+ this.origHeight + "," + this.origWidth +",0, "+ wsize + ");";
						break;
				
					default: //Cts.EM
						System.out.println("Segmenting using EM");
						cmd = "[mask,R2,G2,B2,cX,cY,types] = test_em3(R,G,B,"
								+ this.origHeight + "," + this.origWidth +",0,0);";
						break;
				}

				proxy.eval(cmd);
				
				IJ.showProgress(1);
				
				//get segmented cell centroids and the enhanced R,G and B channels
				MatlabNumericArray arrayX = mProcessor.getNumericArray("cX");
				MatlabNumericArray arrayY = mProcessor.getNumericArray("cY");
				MatlabNumericArray arrayTypes = mProcessor.getNumericArray("types");
				
				double[][] cX = arrayX.getRealArray2D();
				double[][] cY = arrayY.getRealArray2D();
				double[][] types = arrayTypes.getRealArray2D();
				
				//get centroids
				
				int nPoints = cX.length;
				for(int p = 0; p < nPoints; p++){
					Point pp = new Point((int)cX[p][0],(int)cY[p][0]);
					
					int pType = (int)types[p][0];
					if(pType == Consts.ROI_RED){
						pointsRed.add(pp);		
					}else if(pType == Consts.ROI_GREEN){
						pointsGreen.add(pp);
					}else{
						pointsOver.add(pp);
					}
				}	
				
				this.listPoints.add(Consts.ROI_RED, this.pointsRed);
				this.listPoints.add(Consts.ROI_GREEN, this.pointsGreen);
				this.listPoints.add(Consts.ROI_OVERLAP,this.pointsOver);
			    this.listPoints.add(Consts.ROI_NUCLEI,this.pointsNuclei);
				
				int [] coordX1 = getXVector(this.pointsRed);
				int [] coordY1 = getYVector(this.pointsRed);
				int [] coordX2 = getXVector(this.pointsGreen);
				int [] coordY2 = getYVector(this.pointsGreen);
				int [] coordX3 = getXVector(this.pointsOver);
				int [] coordY3 = getYVector(this.pointsOver);

				//create ROIs
				PointRoi pRoi1 = new PointRoi(coordX1, coordY1,pointsRed.size());
				PointRoi pRoi2 = new PointRoi(coordX2, coordY2,pointsGreen.size());
				PointRoi pRoi3 = new PointRoi(coordX3,coordY3,pointsOver.size());
				float i[] = new float[0];
				PointRoi pRoi4 = new PointRoi(i, i,0);
				
				//Set ROIs appearance 
				initRoiAppearance(pRoi1, Consts.ROI_RED);
				initRoiAppearance(pRoi2, Consts.ROI_GREEN);
				initRoiAppearance(pRoi3, Consts.ROI_OVERLAP);
				initRoiAppearance(pRoi4, Consts.ROI_NUCLEI);

				this.listROIs.add(Consts.ROI_RED,pRoi1);
				this.listROIs.add(Consts.ROI_GREEN,pRoi2);
				this.listROIs.add(Consts.ROI_OVERLAP,pRoi3);
				this.listROIs.add(Consts.ROI_NUCLEI,pRoi4);

				updateCountDialog();
				
				this.image.show();
				this.overlay = new Overlay();
				this.overlay.add(pRoi1);
				this.overlay.add(pRoi2);
				this.overlay.add(pRoi3);
				this.overlay.add(pRoi4);
				this.image.setOverlay(this.overlay);
				this.image.repaintWindow();
				
				installListeners();
				

			}catch(MatlabInvocationException e){
				IJ.error("Error: could not detect cells.");
				e.printStackTrace();
			
			}catch(Exception e){
				IJ.error("A erro ocurred in Cell Counter plugin.");
				e.printStackTrace();
			}
			
		} else {
			throw new RuntimeException("not supported");
		}
		
		this.proxy.disconnect();
		
		firstRun = false;
	}


	public void showAbout() {
		IJ.showMessage("UCSF Cell Counter", "semi-automatically counts cells in fluorescence images");
	}
	
	private void initDialogWindow(){
		if(this.dgCount == null){
			this.dgCount = new CellCounterJFrame(this);
		}
	}

	private void initRoiAppearance(PointRoi roi,int roi_type){
		roi.setPointType(Consts.ROI_CURSOR_TYPE[roi_type]);
		roi.setSize(Consts.ROI_CURSOR_SIZE[roi_type]);
		roi.setStrokeColor(currentROIColor[roi_type]);
		roi.setShowLabels(true);	
	}

	public static void main(String[] args) {
		// set the plugins.dir property to make the plugin appear in the Plugins menu
 		Class<?> clazz = UCSF_Cell_Counter.class;
		String url = clazz.getResource("/" + clazz.getName().replace('.', '/') + ".class").toString();
		String pluginsDir = url.substring(5, url.length() - clazz.getName().length() - 6);
		System.setProperty("plugins.dir", pluginsDir);

		// start ImageJ
		new ImageJ();

		//Open test image
		
		OpenDialog fileOpener = new OpenDialog("Choose file.");
		String fileName = fileOpener.getPath();
		ImagePlus image = IJ.openImage(fileName);
		image.show();

		//If gray scale stack, convert to RGB
		
		if(image.getType() != ImagePlus.COLOR_RGB){
			StackConverter stackConv = new StackConverter(image);
			stackConv.convertToRGB();
		}
		
		
		// run the plugin
		IJ.runPlugIn(clazz.getName(), "UCSF Cell Counter");
	}

	@Override
	public void mouseClicked(MouseEvent e) {
		
	}

	@Override
	public void mousePressed(MouseEvent e) {

		if(!isInsideImage || this.selectedROI == -1 || Toolbar.getInstance().getToolId() != Consts.TOOL_ID){
			return;
		}
		
		PointRoi roiTmp = this.listROIs.get(this.selectedROI);
		if(!this.overlay.contains(roiTmp)){ //don't change the ROI if its not visible
			System.out.println("ROI not visible. Nothing to do.");
			return;
		}
			
		ImageCanvas canvas = this.image.getWindow().getCanvas();		
		java.awt.Point loc = canvas.getCursorLoc();
		int	canvasX = loc.x;
		int	canvasY = loc.y;

		int button = e.getButton();
		if(button == MouseEvent.BUTTON1){
			if(e.isControlDown()){ //deletes point in the selected roi
				//find selectedPoint
				findSelection(canvasX,canvasY);
				if(this.selectedPoint != null){ 
					deletePointUpdateROI(); 
					updateCountDialog();
				}	
			}else if(e.isShiftDown()){ //shows pop up to change point color
				findSelection(canvasX,canvasY);
				if(this.selectedPoint != null){ 
					jpopUp.show(e.getComponent(),e.getX(), e.getY());
				}
			}else{ //creates new point on the selected roi			
					createPointUpdateROI(canvasX, canvasY);
					updateCountDialog();
			}
		}
	
	}

	@Override
	public void mouseReleased(MouseEvent e) {
	}

	@Override
	public void mouseEntered(MouseEvent e) {	
		isInsideImage = true;
	}

	@Override
	public void mouseExited(MouseEvent e) {
		isInsideImage = false;
	}


	@Override
	public void imageOpened(ImagePlus imp) {
	}

	@Override
	public void imageClosed(ImagePlus imp) {
		//System.out.println("Image close.");
		if(this.dgCount != null){
			this.dgCount.setVisible(false);
			this.dgCount.dispose();
		}
	}

	@Override
	public void imageUpdated(ImagePlus imp) {
	}

	@Override
	public void adjustmentValueChanged(AdjustmentEvent e) {
	}

	@Override
	public void focusGained(FocusEvent e) {
	}

	@Override
	public void focusLost(FocusEvent e) {
	}
	
	private void installListeners () {			
		
			if(!firstRun){
				return;
			}
		
			//final ImageWindow iw = this.image.getWindow();
			final ImageWindow iw = this.image.getWindow();
			final ImageCanvas ic = iw.getCanvas();
			ImagePlus.addImageListener(this);
			//ic.removeMouseListener(ic);
			//iw.addMouseListener(ic);
			ic.addMouseListener(this);
	} 
	
	/*
	 * Create a int X coordinate vector from the LinkedList
	 */

	private int[] getXVector(LinkedList<Point> points){
		int nPoints = 0;
		if(points != null){
			nPoints = points.size();
		}
		int [] coordX = new int[nPoints];
		for (int i = 0; i < nPoints; i++) {
			Point pp = points.get(i);
			coordX[i] = (int)pp.getX();
		}
		return coordX;
	}
	
	/*
	 * Create a int Y coordinate vector from the LinkedList
	 */
	private int[] getYVector(LinkedList<Point> points){
		int nPoints = 0;
		if(points != null){
			nPoints = points.size();
		}
		int [] coordY = new int[nPoints];
		for (int i = 0; i < nPoints; i++) {
			Point pp = points.get(i);
			coordY[i] = (int)pp.getY();
		}
		return coordY;
	}
	
	/*
	 * Find the selected point on the selected ROI
	 */
	private void findSelection(int xx, int yy){
		//init distance
		int distThres = 10;
		double dist = Math.sqrt(this.height*this.height + this.width*this.width);
		int idxSelect = -1;
		this.selectedPoint = null;
		
		if(this.selectedROI == -1){
			System.err.println("Nothing to do.");
			return;
		}
		
		LinkedList<Point> points = this.listPoints.get(this.selectedROI);
		int nPoints = points.size();
		for(int p=0; p< nPoints; p++){
			double newDist = points.get(p).distance(xx, yy);
			if(newDist < distThres && newDist <= dist){
				dist = newDist;
				idxSelect = p;
			}
		}
		
		if(idxSelect != -1){
			this.selectedPoint = points.get(idxSelect);
		}else{
			this.selectedPoint = null;
		}
		
	}
	
	private void deletePointUpdateROI(){
		
		int sR = this.selectedROI;
		PointRoi roiTmp = this.listROIs.get(sR);
		LinkedList<Point> ptsTmp = this.listPoints.get(sR);
		int idxPoint = ptsTmp.indexOf(this.selectedPoint);
		
		this.overlay.remove(roiTmp);
		this.listROIs.remove(sR);
		ptsTmp.remove(idxPoint);
		
		roiTmp = new PointRoi(getXVector(ptsTmp), getYVector(ptsTmp),ptsTmp.size());
		initRoiAppearance(roiTmp, sR);
		
		this.overlay.add(roiTmp);
		this.listROIs.add(sR, roiTmp);
		this.image.setOverlay(overlay);
		//this.image.repaintWindow();
		this.image.show();	
		
	}
	
	private void createPointUpdateROI(int xx, int yy){
		
		int sR = this.selectedROI;
		PointRoi roiTmp = this.listROIs.get(sR);
		LinkedList<Point> ptsTmp = this.listPoints.get(sR);
		Point newPoint = new Point(xx,yy);
		this.overlay.remove(roiTmp);
		
		if(!ptsTmp.contains(newPoint)){ //only adds point in case it doesn't exist
			ptsTmp.add(newPoint);
		}
		
		roiTmp = new PointRoi(getXVector(ptsTmp), getYVector(ptsTmp),ptsTmp.size());
		initRoiAppearance(roiTmp, sR);
		
		this.listROIs.remove(sR);
		this.overlay.add(roiTmp);
		this.listROIs.add(sR, roiTmp);
		this.image.setOverlay(overlay);
		this.image.show();	
		//this.image.repaintWindow();
		
	}
	
	private void updateCountDialog(){
		
		int numRed = this.listPoints.get(Consts.ROI_RED).size();
		int numGreen = this.listPoints.get(Consts.ROI_GREEN).size();
		int numOver = this.listPoints.get(Consts.ROI_OVERLAP).size();
		int numNuclei = this.listPoints.get(Consts.ROI_NUCLEI).size();
	
		this.count.setRedCells(numRed);
		this.count.setGreenCells(numGreen);
		this.count.setOverlapCells(numOver);
		this.count.setNucleiCells(numNuclei);
		this.count.setTotalCells(numRed+numGreen+numOver+numNuclei);
		
		if(this.dgCount != null){
			this.dgCount.setCounters(this.count);
			this.dgCount.setVisible(true);	
		}
		
	}

	public void setSelectedROI(int s){
		this.selectedROI = s;
	}
	
	public void setNewROIColor(int sR, Color c){
		if(sR >= this.currentROIColor.length){
			return;
		}
		this.currentROIColor[sR] = c;
		this.listROIs.get(sR).setStrokeColor(c);
		this.image.repaintWindow();
	}
	
	public Color getColorSelectedROI(){
		return this.currentROIColor[this.selectedROI];
	}
	
	public Color getColorROI(int sR){
		if(sR >= this.currentROIColor.length){
			return null;
		}
		return this.currentROIColor[sR];
	}
	
	public void clearPoints(int ROI){
		this.listPoints.get(ROI).clear();
		this.overlay.remove(this.listROIs.get(ROI));
		this.listROIs.remove(ROI);
		this.pointsOver.clear();

		float i[] = new float[0];
		PointRoi newRoi = new PointRoi(i, i,0);
		
		this.listROIs.add(ROI, newRoi);
		this.overlay.add(newRoi);
		this.image.setOverlay(overlay);
		this.image.show();	
		//this.image.repaintWindow();
		
		updateCountDialog();
	}
	
	
	public void changePointROI(int destROIIdx){
		
		int origROIIdx = this.selectedROI;

		if(destROIIdx == origROIIdx){ //user trying to move point to it's own class
			return;
		}
		
		Point p = this.selectedPoint;

		//add point to destination ROI
		this.listPoints.get(destROIIdx).add(p);
		int nPointsDest = this.listPoints.get(destROIIdx).size();
		PointRoi destPointROI = this.listROIs.get(destROIIdx);
		this.overlay.remove(destPointROI);
		this.listROIs.remove(destROIIdx);
		
		PointRoi newDestPointROI = new PointRoi(getXVector(this.listPoints.get(destROIIdx)),
												getYVector(this.listPoints.get(destROIIdx)),nPointsDest);
		initRoiAppearance(newDestPointROI, destROIIdx);	
		this.listROIs.add(destROIIdx, newDestPointROI);
		this.overlay.add(newDestPointROI);
		
		//remove point from origin ROI
		this.listPoints.get(origROIIdx).remove(p);
		int nPointsOrig = this.listPoints.get(origROIIdx).size();
		PointRoi origPointROI = this.listROIs.get(origROIIdx);
		this.overlay.remove(origPointROI);
		this.listROIs.remove(origROIIdx);
		
		PointRoi newOrigPointROI = new PointRoi(getXVector(this.listPoints.get(origROIIdx)),
												getYVector(this.listPoints.get(origROIIdx)),nPointsOrig);
		initRoiAppearance(newOrigPointROI, origROIIdx);
		this.listROIs.add(origROIIdx, newOrigPointROI);
		this.overlay.add(newOrigPointROI);
		
		this.image.setOverlay(this.overlay);
		updateCountDialog();
		this.image.show();
		//this.image.repaintWindow();	
	}
	
	public void setSegMethod(int m){
		this.segMethod = m;
	}

	public int getSegMethod(){
		return this.segMethod;
	}
	
	public void hideROI(int roi){
		if(this.overlay != null){
			
			PointRoi roiTmp = this.listROIs.get(roi);
			this.overlay.remove(roiTmp);
			this.image.repaintWindow();
		}
	}
	
	public void showROI(int roi){
		if(this.overlay != null){			
			PointRoi roiTmp = this.listROIs.get(roi);
			boolean isInOverlay = this.overlay.contains(roiTmp);
			if(!isInOverlay){
				this.overlay.add(roiTmp);
				this.image.repaintWindow();
			}
		}
	}
	
	public void initPointROIs(){
		
		float i[] = new float[0];
		PointRoi p1 = new PointRoi(i, i,0);
		PointRoi p2 = new PointRoi(i, i,0);
		PointRoi p3 = new PointRoi(i, i,0);
		PointRoi p4 = new PointRoi(i, i,0);
		
		//Set ROIs appearance 
		initRoiAppearance(p1, Consts.ROI_RED);
		initRoiAppearance(p2, Consts.ROI_GREEN);
		initRoiAppearance(p3, Consts.ROI_OVERLAP);
		initRoiAppearance(p4, Consts.ROI_NUCLEI);
		
		this.listPoints.add(Consts.ROI_RED,new LinkedList<Point>());
		this.listPoints.add(Consts.ROI_GREEN,new LinkedList<Point>());
		this.listPoints.add(Consts.ROI_OVERLAP,new LinkedList<Point>());
	    this.listPoints.add(Consts.ROI_NUCLEI,new LinkedList<Point>());

		this.listROIs.add(Consts.ROI_RED,p1);
		this.listROIs.add(Consts.ROI_GREEN,p2);
		this.listROIs.add(Consts.ROI_OVERLAP,p3);
		this.listROIs.add(Consts.ROI_NUCLEI,p4);

		updateCountDialog();
		
		this.image.show();
		this.overlay = new Overlay();
		this.overlay.add(p1);
		this.overlay.add(p2);
		this.overlay.add(p3);
		this.overlay.add(p4);
		this.image.setOverlay(this.overlay);
		this.image.repaintWindow();
		
	}
	
	public void loadUCSFCellCounterData(File f){
		try{
			
			this.pointsRed.clear();
			this.pointsGreen.clear();
			this.pointsOver.clear();
			this.pointsNuclei.clear();
			
			this.listPoints.clear();
			this.listROIs.clear();
			if(this.overlay != null){
				this.overlay.clear();
			}else{
				this.overlay = new Overlay();
			}
			
			LinkedList<LinkedList<Point>> data = FileHelper.loadPointList(f);
			LinkedList<Point> redTmp = data.get(Consts.ROI_RED);
			LinkedList<Point> greenTmp = data.get(Consts.ROI_GREEN);
			LinkedList<Point> overTmp = data.get(Consts.ROI_OVERLAP);
			LinkedList<Point> nucleiTmp = data.get(Consts.ROI_NUCLEI);

			this.listPoints.add(Consts.ROI_RED,data.get(Consts.ROI_RED));
			this.listPoints.add(Consts.ROI_GREEN,data.get(Consts.ROI_GREEN));
			this.listPoints.add(Consts.ROI_OVERLAP,data.get(Consts.ROI_OVERLAP));
			this.listPoints.add(Consts.ROI_NUCLEI,data.get(Consts.ROI_NUCLEI));
			
			int nPR = redTmp.size();
			PointRoi roiR = new PointRoi(getXVector(redTmp),getYVector(redTmp),nPR);
			int nPG = greenTmp.size();
			PointRoi roiG = new PointRoi(getXVector(greenTmp),getYVector(greenTmp),nPG);
			int nPO = overTmp.size();
			PointRoi roiO = new PointRoi(getXVector(overTmp),getYVector(overTmp),nPO);
			int nPN = nucleiTmp.size();
			PointRoi roiN = new PointRoi(getXVector(nucleiTmp),getYVector(nucleiTmp),nPN);
			
			//Set ROIs appearance 
			initRoiAppearance(roiR, Consts.ROI_RED);
			initRoiAppearance(roiG, Consts.ROI_GREEN);
			initRoiAppearance(roiO, Consts.ROI_OVERLAP);
			initRoiAppearance(roiN, Consts.ROI_NUCLEI);

			
			//set counters
			if(this.count != null){
				this.count.reset();
			}else{
				this.count = new CellCount();
			}
			updateCountDialog();
			installListeners();

			this.listROIs.add(Consts.ROI_RED,roiR);
			this.listROIs.add(Consts.ROI_GREEN,roiG);
			this.listROIs.add(Consts.ROI_OVERLAP,roiO);
			this.listROIs.add(Consts.ROI_NUCLEI,roiN);
			
			this.overlay.add(roiR);
			this.overlay.add(roiG);
			this.overlay.add(roiO);
			this.overlay.add(roiN);
			this.image.setOverlay(overlay);
			this.image.show();	

		}catch(Exception e){
			IJ.showMessage("Could not load the points.");
			e.printStackTrace();
		}
		
		
	}
	
	public void saveUCSFCellCounterData(File f){
		try{
			boolean yes = true;
			if(f.exists()){
				yes = IJ.showMessageWithCancel("Save as...", "File already exists. Rewrite?");
			}
			
			if(yes){
				FileHelper.savePointList(f, (LinkedList<LinkedList<Point>>)this.listPoints);
				IJ.showMessage("File saved successfully.");
			}
					
		}catch(IOException e){
			IJ.showMessage("Could not save file.");
			e.printStackTrace();
		}
		
	}
	
	private void initPopUpColorMenu(){
		if(this.jpopUp == null){
			this.jpopUp = new JPopupMenu();
		}
		JMenuItem itemR = new JMenuItem("Red");
		JMenuItem itemG = new JMenuItem("Green");
		JMenuItem itemO = new JMenuItem("Over");
		JMenuItem itemN = new JMenuItem("Nuclei");
		
		PopupListener popupListener = new PopupListener();
		popupListener.setApp(this);
	    
	    itemR.addActionListener(popupListener);
	    itemG.addActionListener(popupListener);
	    itemO.addActionListener(popupListener);
	    itemN.addActionListener(popupListener);
	    
		jpopUp.add(itemR);
		jpopUp.add(itemG);
		jpopUp.add(itemO);
		jpopUp.add(itemN);
		//jpopUp.setVisible(false);		
	}
}
