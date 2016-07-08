public class CommissionDetailController {
    public CommissionData CommData{get;set;}

    public string TheCategory{get;set;}
    
    private string LabelPrfix='';
    public string getLabelPrefix(){
        if(LabelPrfix=='')LabelPrfix=CommissionDetail_Helper.GetLabelPrefix(TheCategory,CommData.Num);
        return LabelPrfix;
    }
    
    public string getSectionHeader(){
        return CommissionDetail_Helper.GetSectionHeader(TheCategory,CommData.Num);
    }

    
}