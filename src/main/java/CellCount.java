
public class CellCount {
	

	private int totalCells;
	private int redCells;
	private int greenCells;
	private int blueCells;
	private int overlapCells;
	private int nucleiCells;
	
	public CellCount(){
		totalCells = 0;
		redCells = 0;
		greenCells = 0;
		blueCells = 0;
		overlapCells = 0;
		nucleiCells = 0;
	}
	
	public int getTotalCells() {
		return totalCells;
	}
	public void setTotalCells(int totalCells) {
		this.totalCells = totalCells;
	}
	
	public int getRedCells() {
		return redCells;
	}
	public void setRedCells(int redCells) {
		this.redCells = redCells;
	}
	public int getGreenCells() {
		return greenCells;
	}
	public void setGreenCells(int greenCells) {
		this.greenCells = greenCells;
	}
	public int getBlueCelsl() {
		return blueCells;
	}
	public void setBlueCells(int blueCell) {
		this.blueCells = blueCell;
	}

	public int getOverlapCells() {
		return overlapCells;
	}

	public void setOverlapCells(int overlapCells) {
		this.overlapCells = overlapCells;
	}
	
	public int getNucleiCells() {
		return nucleiCells;
	}

	public void setNucleiCells(int nucleiCells) {
		this.nucleiCells = nucleiCells;
	}
	
	public void reset(){
		totalCells = 0;
		redCells = 0;
		greenCells = 0;
		blueCells = 0;
		overlapCells = 0;	
		nucleiCells = 0;
	}


}
