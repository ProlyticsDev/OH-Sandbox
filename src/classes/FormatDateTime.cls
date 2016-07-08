public class FormatDateTime {
    public DateTime dateTimeValue { get; set; }
    public String formatString {get; set;}
    
    public String getTimeZoneValue() {
        if( dateTimeValue != null ) {
            String localeFormatDT = dateTimeValue.format(formatString);
            return localeFormatDT;
        }
        return null;
    }
}