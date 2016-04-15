import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class PopupListener implements ActionListener{
	
		private UCSF_Cell_Counter app;

		@Override
		public void actionPerformed(ActionEvent e) {
			
			int selectedItem = 0;
			
			if(e.getActionCommand().equals("Red")){
				selectedItem = Consts.ROI_RED;
			}else if(e.getActionCommand().equals("Green")){
				selectedItem = Consts.ROI_GREEN;
			}else if(e.getActionCommand().equals("Over")){
				selectedItem = Consts.ROI_OVERLAP;
			}else if(e.getActionCommand().equals("Nuclei")){
				selectedItem = Consts.ROI_NUCLEI;
			}
			
			this.app.changePointROI(selectedItem);
		}
		
		public void setApp(UCSF_Cell_Counter app){
			this.app = app;
		}

}