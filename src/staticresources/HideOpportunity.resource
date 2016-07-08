document.addEventListener('DOMContentLoaded', function () {
	var url = window.location.href;
	var tabUrl = "https://ap1.salesforce.com/006/o";
	if(url.indexOf(tabUrl) !== -1){
		var x = document.getElementsByName("new");
		var i;
		var newBtn;
		for (i = 0; i < x.length; i++) {
    		if (x[i].type == "button") {
        		newBtn = x[i];
    		}
		}
		newBtn.style.display = 'none';
	}
});