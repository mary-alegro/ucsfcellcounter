import java.io.Serializable;



public class Point implements Serializable{
	
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private int x;
	private int y;
	private int distThresh = 8;
	
	public Point(int x, int y){
		this.x = x;
		this.y = y;
	}

	public int getX() {
		return x;
	}

	public void setX(int x) {
		this.x = x;
	}

	public int getY() {
		return y;
	}

	public void setY(int y) {
		this.y = y;
	}
	
	public boolean equals(Object o){
		Point p = (Point) o;
		if(p.getX() == this.x && p.getY() == this.y){
			return true;
		}else{
			return false;
		}
	}
	
	public boolean isClose (int x,int y) {

		double dist = distance(x,y);
		if(dist <= distThresh){
			return true;
		}else{
			return false;
		}
		
	}
	
	public double distance(int x,int y){
		double distance = (double)(x - this.x) * (double)(x - this.x) + (double)(y - this.y) * (double)(y - this.y);
		distance = Math.sqrt(distance);
		return distance;
	}
	
	public String toString(){
		return "X: " + this.x + " y: " + this.y;
	}
	

}
