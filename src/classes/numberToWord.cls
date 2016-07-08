public with sharing class numberToWord 
{
	private static string[] arrayTo19 = new string[]{'ZERO','ONE','TWO','THREE','FOUR','FIVE','SIX',
		'SEVEN','EIGHT','NINE','TEN','ELEVEN','TWELVE','THIRTEEN',
		'FOURTEEN','FIFTEEN','SIXTEEN','SEVENTEEN','EIGHTEEN','NINETEEN'};
	
	private static string[] arrayTens = new string[]{'TWENTY','THIRTY','FORTY','FIFTY','SIXTY','SEVENTY','EIGHTY','NINETY'};
	
	private static string[] arrayDenominations = new string[]{ '','THOUSAND','MILLION','BILLION','TRILLION'};
	
	//Convert a value less than 100 to word
	public static string ConvertNN(integer val) 
	{
		if (val < 20)
		{
			return arrayTo19[val];
		}
		if(val == 100)
		{
			return 'ONE HUNDRED';
		}
		for (integer v = 0; v < arrayTens.size(); v++) 
		{
			string dcap = arrayTens[v];
			integer dval = 20 + 10 * v;
        	if (dval + 10 > val) 
        	{
				if (Math.Mod(val,10) != 0)
				{
					return dcap + ' ' + arrayTo19[Math.Mod(val,10)];
				}
				return dcap;
			}
		}
		return '';  
	}
	
	//Convert a value less than 1000 to word
	public static string ConvertNNN(integer val) 
	{
		string word = '';
		integer rem = val / 100;
		integer mod = Math.mod(val,100);
		if (rem > 0) 
		{
			word = arrayTo19[rem] + ' HUNDRED';
			if (mod > 0) 
			{
				word += ' ';
			}
		}
		if (mod > 0) 
		{
			word += numberToWord.ConvertNN(mod);
		}
		return word;
	}
    
    public static string EnglishNumbers(long val) 
    {
		if (val < 100) 
		{
			return numberToWord.ConvertNN(val.intValue());
		}
		if (val < 1000) 
		{
			return numberToWord.ConvertNNN(val.intValue());
		}
		for (integer v = 0; v < arrayDenominations.size(); v++) 
		{
			integer didx = v - 1;
			integer dval = (integer)Math.pow(1000, v);
			if (dval > val) 
			{
				integer mod = (integer)Math.pow(1000, didx);
				integer l = (integer) val / mod;
				integer r = (integer) val - (l * mod);
				string ret = numberToWord.ConvertNNN(l) + ' ' + arrayDenominations[didx];
				if (r > 0) 
				{
					ret += ', ' + EnglishNumbers(r);
				}
				return ret;
			}
		}
		return '';
	}
}