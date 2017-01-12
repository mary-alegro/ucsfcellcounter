import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.LinkedList;


public class FileHelper {
	
	public FileHelper(){
	}
	
	public static LinkedList<LinkedList<Point>> loadPointList(File f) throws IOException, ClassNotFoundException{
		LinkedList<LinkedList<Point>> lPoints = null;

	         FileInputStream fileIn = new FileInputStream(f);
	         ObjectInputStream in = new ObjectInputStream(fileIn);
	         lPoints = (LinkedList<LinkedList<Point>>) in.readObject();
	         in.close();
	         fileIn.close();
     
	     return lPoints;
		
	}
	
	public static void savePointList(File f,LinkedList<LinkedList<Point>> points) throws IOException{

		         FileOutputStream fileOut = new FileOutputStream(f);
		         ObjectOutputStream out = new ObjectOutputStream(fileOut);
		         out.writeObject(points);
		         out.close();
		         fileOut.close();
		         System.out.println("Serialized data is saved in " + f.getName());

		
	}
 
}
