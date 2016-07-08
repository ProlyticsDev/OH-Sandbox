@isTest
public class FormatDateTimeTest {

    static testMethod void testFormatDateTime() {
        FormatDateTime dt = new FormatDateTime();
        dt.dateTimeValue = Datetime.now();
        dt.formatString = 'dd/MM/yyyy';
        System.assertEquals(Datetime.now().format('dd/MM/yyyy'), dt.getTimeZoneValue());
        
        dt.dateTimeValue = null;
        System.assertEquals(null, dt.getTimeZoneValue());
    }

}