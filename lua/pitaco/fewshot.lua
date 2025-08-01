local fewshot = {
	messages = {
		{
			role = "user",
			content = [[
04 function calculateMaxSum(arr) {
05     const n = arr.length;
06     if (n === 0) return 0;
07     if (n === 1) return arr[0];
08     let dp = new Array(n).fill(0);
09     dp[0] = arr[0];
10     dp[1] = Math.max(arr[0], arr[1]);
11     for (let i = 2; i < n; i++) {
12         dp[i] = Math.max(dp[i - 1], dp[i - 2] + arr[i]);
13     }
14     return dp[n - 1];
15 }]],
		},
		{
			role = "assistant",
			content = [[
line=4: The function name 'calculateMaxSum' is descriptive, but consider adding comments to explain its purpose.
line=8: The variable name 'dp' is unclear. A more informative name could be 'maxSum' or 'optimalSolution'.
line=9: There are no comments explaining the meaning of the 'dp' array values and how they relate to the problem statement.
line=11: There are no comments explaining the logic and purpose of the for loop]],
		},
		{
			role = "user",
			content = [[
673    for (let i: number = 0; i < l; i++) {
674       let notAddr: boolean = false;
675       // non standard input
676       if (items[i].scriptSig && !items[i].addr) {
677         items[i].addr = 'Unparsed address [' + u++ + ']';
678         items[i].notAddr = true;
679         notAddr = true;
680       }
681
682       // non standard output
683       if (items[i].scriptPubKey && !items[i].scriptPubKey.addresses) {
684         items[i].scriptPubKey.addresses = ['Unparsed address [' + u++ + ']'];]],
		},
		{
			role = "assistant",
			content = [[
line=673: The variable name 'i' and 'l' are unclear and easily confused with other characters like '1'. More meaningful names could be 'index' and 'length' respectively.
line=674: The variable name 'notAddr' is unclear and a double negative. An alternative could be 'hasUnparsedAddress'.
line=676: The comment "non standard input" is not very informative. It could be more descriptive, e.g., "Check for non standard input address"
line=682: The comment "non standard output" is not very informative. It could be more descriptive, e.g., "Check for non standard output address"
line=683: The variable name 'items' might be more informative if changed to 'transactions' or 'txItems'.
line=684: The array element 'Unparsed address [' + u++ + ']' could use a more descriptive comment, e.g., "Assign a unique identifier to non standard output addresses"
line=684: The variable name 'u' is unclear. A more meaningful name could be 'unparsedAddressCount' or 'unparsedAddressId'.]],
		},
		{
			role = "user",
			content = [[
01 function fetchData(url) {
02     return fetch(url)
03         .then(response => response.json())
04         .then(data => {
05             console.log(data);
06             return data;
07         })
08         .catch(error => console.error('Error fetching data:', error));
09 }]],
		},
		{
			role = "assistant",
			content = [[
line=1: The function name 'fetchData' is clear, but consider adding JSDoc comments to describe the function's purpose and parameters.
line=5: Avoid using console.log for production code. Consider using a logging library or removing it after debugging.
line=8: The error message could be more descriptive, e.g., 'Failed to fetch data from the provided URL'.]],
		},
		{
			role = "user",
			content = [[
01 interface User {
02     id: number;
03     name: string;
04     email: string;
05     isActive: boolean;
06 }

07 function createUser(user: User): string {
08     if (!user.name || !user.email) {
09         throw new Error('User must have a name and email');
10     }
11     return `User ${user.name} created successfully!`;
12 }]],
		},
		{
			role = "assistant",
			content = [[
line=1: The interface 'User' is well-defined, but consider adding comments to describe each property.
line=7: The function 'createUser' is clear, but consider adding JSDoc comments to describe its parameters and return type.
line=9: The error message could be more informative, e.g., 'User creation failed: Name and email are required fields'.]],
		},
		{
			role = "user",
			content = [[
01 function accessProperty(obj) {
02     return obj.property.toUpperCase();
03 }
04
05 const result = accessProperty(undefined);
06 console.log(result);]],
		},
		{
			role = "assistant",
			content = [[
line=2: Attempting to access 'property' on 'obj' will throw an error if 'obj' is undefined. Consider adding a check to ensure 'obj' is defined before accessing its properties.
line=5: Passing 'undefined' to 'accessProperty' will cause an error. Ensure that 'obj' is defined before calling 'accessProperty'.]],
		},
		{
			role = "user",
			content = [[
01 function fetchData(url) {
02     for (let i = 0; i < 1000; i++) {
03         fetch(url)
04             .then(response => response.json())
05             .then(data => console.log(data))
06             .catch(error => console.error('Error:', error));
07     }
08 }]],
		},
		{
			role = "assistant",
			content = [[
line=2: Making 1000 fetch requests in a loop can lead to performance issues and server overload. Consider batching requests or using a more efficient approach.
line=5: Avoid using console.log for production code. Consider using a logging library or removing it after debugging.]],
		},
		{
			role = "user",
			content = [[
01 function calculateFactorial(n) {
02     if (n < 0) return -1;
03     if (n === 0) return 1;
04     return n * calculateFactorial(n - 1);
05 }
06
07 const result = calculateFactorial(100000);
08 console.log(result);]],
		},
		{
			role = "assistant",
			content = [[
line=4: Recursive calls with large input like 100000 can lead to a stack overflow. Consider using an iterative approach for large inputs.
line=8: Avoid using console.log for production code. Consider using a logging library or removing it after debugging.]],
		},
	},
}

return fewshot
