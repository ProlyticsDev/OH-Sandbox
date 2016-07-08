public with sharing class TStringUtils {
    
    public static Map<String,List<String>> getDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName, Map<String, String> projects){
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        if (!Schema.getGlobalDescribe().containsKey(pObjName))
            return objResults;
        //get the type being dealt with
        Schema.SObjectType pType = Schema.getGlobalDescribe().get(pObjName);
        return getDependentOptions2(pType,pControllingFieldName,pDependentFieldName,projects);        
    }
    
    public static List<Integer> B64ToBytes (String sIn) {
        Map<Integer,Integer> base64 = new Map<Integer,Integer>{65=>0,66=>1,67=>2,68=>3,69=>4,70=>5,71=>6,72=>7,73=>8,74=>9,75=>10,76=>11,77=>12,78=>13,79=>14,80=>15,81=>16,82=>17,83=>18,84=>19,85=>20,86=>21,87=>22,88=>23,89=>24,90=>25
                                                               ,97=>26,98=>27,99=>28,100=>29,101=>30,102=>31,103=>32,104=>33,105=>34,106=>35,107=>36,108=>37,109=>38,110=>39,111=>40,112=>41,113=>42,114=>43,115=>44,116=>45,117=>46,118=>47,119=>48,120=>49,121=>50,122=>51
                                                               ,48=>52,49=>53,50=>54,51=>55,52=>56,53=>57,54=>58,55=>59,56=>60,57=>61,43=>62,47=>63};

        List<Integer> lstOut = new List<Integer>();
        if ( sIn == null || sIn == '' ) return lstOut;
        
        sIn += '='.repeat( 4 - Math.mod( sIn.length(), 4) );

        for ( Integer idx=0; idx < sIn.length(); idx += 4 ) {
            if ( base64.get(sIn.charAt(idx+1)) != null ) lstOut.add( (base64.get(sIn.charAt(idx)) << 2) | (base64.get(sIn.charAt(idx+1)) >>> 4) );
            if ( base64.get(sIn.charAt(idx+2)) != null ) lstOut.add( ((base64.get(sIn.charAt(idx+1)) & 15)<<4) | (base64.get(sIn.charAt(idx+2)) >>> 2) );
            if ( base64.get(sIn.charAt(idx+3)) != null ) lstOut.add( ((base64.get(sIn.charAt(idx+2)) & 3)<<6) | base64.get(sIn.charAt(idx+3)) );
        }

        //System.Debug('B64ToBytes: [' + sIn + '] = ' + lstOut);
        return lstOut;
    }//B64ToBytes
    
    // Converts a base64 string into a list of integers indicating at which position the bits are on
    public static List<Integer> cnvBits (String b64Str) {
        List<Integer> lstOut = new List<Integer>();
        if ( b64Str == null || b64Str == '' ) return lstOut;

        List<Integer> lstBytes = B64ToBytes(b64Str);

        Integer i, b, v;
        for ( i = 0; i < lstBytes.size(); i++ ) {
            v = lstBytes[i];
            //System.debug ( 'i['+i+'] v['+v+']' );
            for ( b = 1; b <= 8; b++ ) {
                //System.debug ( 'i['+i+'] b['+b+'] v['+v+'] = ['+(v & 128)+']' );
                if ( ( v & 128 ) == 128 ) lstOut.add( (i*8) + b );
                v <<= 1;
            }
        }

        //System.Debug('cnvBits: [' + b64Str + '] = ' + lstOut);
        return lstOut;
    }

    public static Map<String,List<String>> getDependentOptions2(Schema.SObjectType pType, String pControllingFieldName, String pDependentFieldName, Map<String, String> projects) {
        Map<String,List<String>> mapResults = new Map<String,List<String>>();
        
        //verify/get object schema
        //Schema.SObjectType pType = Schema.getGlobalDescribe().get(pObjName);
        if ( pType == null ) return mapResults;
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
        
        //verify field names
        if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName)) return mapResults;
        
        //get the control & dependent values
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
        
        //clear heap
        objFieldMap = null;
        
        //initialize results mapping
        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){
            Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
            //get the label
            String pControllingLabel = ctrl_entry.getLabel();
            if (projects.containsKey(pControllingLabel))
                mapResults.put( pControllingLabel, new List<String>());
        }
        //cater for null and empty
        mapResults.put('', new List<String>());
        mapResults.put(null, new List<String>());
        
        //serialize dep entries
        List<TStringUtils.TPicklistEntry> objDS_Entries = new List<TStringUtils.TPicklistEntry>();
        objDS_Entries = (List<TStringUtils.TPicklistEntry>)JSON.deserialize(JSON.serialize(dep_ple), List<TStringUtils.TPicklistEntry>.class);
        
        List <Integer>validIndexes;
        for (TStringUtils.TPicklistEntry objDepPLE : objDS_Entries){
            validIndexes = cnvBits(objDepPLE.validFor);
            //System.Debug(‘cnvBits: [‘ + objDepPLE.label + ‘] = ‘ + validIndexes);
            for (Integer validIndex : validIndexes){
                if (mapResults.get( ctrl_ple[validIndex-1].getLabel() ) != null) {
                    mapResults.get( ctrl_ple[validIndex-1].getLabel() ).add( objDepPLE.label );
                }
            }
        }
        
        //clear heap
        objDS_Entries = null;
        
        return mapResults;
    }
    
    public class TPicklistEntry{
        public string active {get;set;}
        public string defaultValue {get;set;}
        public string label {get;set;}
        public string value {get;set;}
        public string validFor {get;set;}
        public TPicklistEntry(){
            
        }
    }
    
}