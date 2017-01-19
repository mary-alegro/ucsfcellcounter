


import java.io.File;
import java.util.LinkedList;

public class TestSerialization {

	public static void main(String[] args) {
		LinkedList<Point> points1 = new LinkedList<Point>();
		LinkedList<Point> points2 = new LinkedList<Point>();
		LinkedList<Point> points3 = new LinkedList<Point>();
		LinkedList<LinkedList<Point>> lol = new LinkedList<LinkedList<Point>>();
		
		Point p1 = new Point(10,20);
		Point p2 = new Point(30,40);
		Point p3 = new Point(100,200);
		Point p4 = new Point(1000,2000);
		Point p5 = new Point(1,2);
		
		points1.add(p1);
		points1.add(p2);
		points2.add(p3);
		points3.add(p4);
		points3.add(p5);
		
		lol.add(points1);
		lol.add(points2);
		lol.add(points3);
		try{
		
		File f = new File("/home/maryana/test_ser.dat");
		//FileHelper.savePointList(f,lol);
		
		System.out.println("Absolut path: " + f.getAbsolutePath());
		System.out.println("Path: " + f.getPath());
		
		LinkedList<LinkedList<Point>> lol2 = FileHelper.loadPointList(f);     
	     if(lol2 != null){
	    	 int nLists = lol2.size();
	    	 for(int l = 0; l < nLists; l++){
	    		 System.out.println("Elements in list #"+(l+1));
	    		 LinkedList<Point> inList = lol2.get(l);
	    		 for (Point point : inList) {
					System.out.println("    " + point);
				}
	    		 
	    	 }
	    	 
	     }else{
	    	 System.out.println("Load failed. Points list wasn't initialized.");
	     }

		}catch(Exception e){
			e.printStackTrace();
		}
	}

}
