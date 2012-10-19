component extends="mxunit.framework.TestCase" {

	public any function beforeTests() {
		variables.instance = {};
		variables.instance.ldap = createObject("component", "ldap").init();
		variables.instance.connectionDetails = {
			server 		= 	'', // LDAP Server
			dn			=	'', // LDAP username
			password	=	'' // LDAP password
		};
	}	
		
	public any function setUp() {
	
	}
	
	public any function tearDown() {
		
	}
	
	public any function getServerDetails() {
		debug(server);
	}
	
	public any function test_Return_LDAP_CFC() {
		debug(variables.instance.ldap);
	}
	
	public any function test_Memento() {
		debug(variables);
	}
	
	public any function test_Return_Of_JavaLoader() {
		loader = variables.instance.ldap.getJavaLoader();
		debug(loader);
	}
	
	public any function test_Return_Loaded_Class() {
		ldapConnection = variables.instance.ldap.getJavaLoader().create("com.novell.ldap.LDAPConnection");
		debug(ldapConnection);
	}
	
	public any function test_Search_Function() {
		// Build the connection
		variables.instance.ldap.buildConnection(argumentCollection=variables.instance.connectionDetails);
		// Perform the search
		startCount = getTickCount();
		var returnData = variables.instance.ldap.search(filter='(uid=blahblah)',attributes='dn,blah,blah',base='ou=accounts');
		endCount = getTickCount();
		timeTaken = endCount-startCount;
		debug(timeTaken & ' milliseconds');
		debug(returnData);
		assertIsQuery(returnData);
	}
		
}