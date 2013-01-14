var PI = 3.141592653;
var K  = 1024;


for(var i = 0; i <= 90; i++)
{
	if(i % 10 == 0)
	{
		console.log("----------------------------------------------");
		console.log("angle\trads\thex\tsin\tcos");
		console.log("----------------------------------------------");
	}
	var rads = i * (PI / 180);
	console.log(i + "\t" + rads.toFixed(4) + "\t" + (rads * (K)).toString(16).substring(0,6) + "\t" +
				Math.sin( rads ).toFixed(4) + "\t" + Math.cos( rads ).toFixed(4) + "\t" +
				(K * Math.sin( rads ).toFixed(4)).toString(16).substring(0,6) + "\t" +
				(K * Math.cos( rads ).toFixed(4)).toString(16).substring(0,6) );
}


console.log('VHDL Constants\n-------');
for ( var i = 1; i <= 8; i++)
{
	console.log(", to_signed(" + K * 45 * Math.pow(2,-i) + ", 17)") 
}