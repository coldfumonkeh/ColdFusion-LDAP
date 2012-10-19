<cfcomponent output="false" hint="Encapsulates LDAP operations using JAVA ldap oeprations." accessors="true">
	
	<cfproperty name="javaLoader" 	type="any" 		default="" />
	<cfproperty name="server" 		type="string" 	default="" />
	<cfproperty name="dn" 			type="string" 	default="" />
	<cfproperty name="password" 	type="string" 	default="" />
	<cfproperty name="port" 		type="string" 	default="389" />
	<cfproperty name="timeout" 		type="string" 	default="1000" />
	<cfproperty name="secure" 		type="string" 	default="false" />
	
	<!--- *********************************************************** --->
	<!--- init                                                        --->
	<!--- Initalizes the Ldap object.          						  --->
	<!--- *********************************************************** --->
	<cffunction access="public" name="init" output="false" returntype="any" hint="Initalizes the Ldap object and opens a connection.">
		<cfset var arrPaths = [ getDirectoryFromPath(getCurrentTemplatePath()) & 'ldap.jar' ] />
		<cfset var objJLoader = createObject("component","javaloader.JavaLoader").init(arrPaths) />
			<cfset setJavaLoader(objJLoader) />
		<cfreturn this />
	</cffunction>
	
	<!--- *********************************************************** --->
	<!--- buildConnection                                             --->
	<!--- Opens a connection.          								  --->
	<!--- *********************************************************** --->
	<cffunction name="buildConnection" output="false" access="public" returntype="void" hint="I store the connection details for the ldap connection.">
		<cfargument name="server" 	type="string" 	required="yes" 	default="#getServer()#"		hint="The ldap server to contact." />
		<cfargument name="dn" 		type="string" 	required="yes" 	default="#getDn()#"			hint="The distinguished name of the ldap user to connect with." />
		<cfargument name="password" type="string" 	required="yes" 	default="#getPassword()#"	hint="The password name of the ldap user to connect with." />
		<cfargument name="port" 	type="string" 	required="no" 	default="#getPort()#" 		hint="The port to communicate to the ldap server on." />
		<cfargument name="timeout" 	type="string" 	required="no" 	default="#getTimeout()#" 	hint="The timeout for the ldap connection." />
		<cfargument name="secure" 	type="boolean" 	required="no" 	default="#getSecure()#" 	hint="Whether or not to establish a secure connection." />
			<cfset setServer(arguments.server) />
			<cfset setDn(arguments.dn) />
			<cfset setPassword(arguments.password) />
			<cfset setPort(arguments.port) />
			<cfset setTimeout(arguments.timeout) />
			<cfset setSecure(arguments.secure) />
			<cfinvoke method="connection_start">
	</cffunction>
	
	<!--- *********************************************************** --->
	<!--- connection_start                                            --->
	<!--- Starts the ldap connection.                                 --->
	<!--- *********************************************************** --->
	<cffunction access="private" name="connection_start" output="false" returntype="void" hint="Starts the ldap connection.">
		<cfset var ssf= "" />
			<cfif getSecure()>
				<cfset ssf = getJavaLoader().create("com.novell.ldap.LDAPJSSESecureSocketFactory").init() />
				<cfset This.connection = getJavaLoader().create("com.novell.ldap.LDAPConnection").init( ssf ) />
			<cfelse>
				<cfset This.connection = getJavaLoader().create("com.novell.ldap.LDAPConnection").init() />			
			</cfif>
			<cfset This.connection.connect( getServer(), getPort() ) />
			<!--- string object to get byte array for password --->
			<cfset userPwObj = createobject("java", "java.lang.String").init( getPassword() ) />
			<!--- create a contraints object used for the bind (to set timeout) --->
			<cfset This.constraints = getJavaLoader().create("com.novell.ldap.LDAPConstraints").init() />
			<cfset This.constraints.setTimeLimit( getTimeout() ) />
			<!--- bind to LDAP server --->				
			<cfset This.connection.bind(3, getDn(), userPwObj.getBytes("UTF8"),This.constraints) />
	</cffunction>
	
	<!--- *********************************************************** --->
	<!--- add                                                         --->
	<!--- Performs an ldap add.                                       --->
	<!--- *********************************************************** --->
	<cffunction access="public" name="add" output="FALSE" returntype="void" hint="Performs an ldap add.">
		<cfargument name="userdn" 		type="string" required="yes" hint="The desired distinguished name of the ldap user to add." />
		<cfargument name="userdetails" 	type="struct" required="yes" hint="A structure containing the new values for the object." >
			<cfset var LDAPAttribute 	=	"" />
			<cfset var LDAPEntryClass 	=	"" />
			<cfset var LDAPAttributeSet = 	getJavaLoader().create("com.novell.ldap.LDAPAttributeSet").init() />
			<cfset var keysToStruct 	= 	StructKeyArray(arguments.userdetails) />
				<!--- Build java ldapattribute set  --->
				<cfloop index = "i" from = "1" to = "#ArrayLen(keysToStruct)#">
					<cfset LDAPAttribute = getJavaLoader().create("com.novell.ldap.LDAPAttribute").init(keysToStruct[i],arguments.userdetails[keysToStruct[i]])/>
					<cfset LDAPAttributeSet.Add(LDAPAttribute) />
				</cfloop>
				<!--- Create an LDAP entry using the passed in details---> 
				<cfset LDAPEntryClass = getJavaLoader().create("com.novell.ldap.LDAPEntry").init(arguments.userdn, LDAPAttributeSet) />
				<cfset This.connection.add(LDAPEntryClass) />
	</cffunction>
	
	<!--- *********************************************************** --->
	<!--- connection_end                                              --->
	<!--- Closes the ldap connection.                                 --->
	<!--- *********************************************************** --->
	<cffunction access="public" name="connection_end" output="false" returntype="void" hint="Closes the ldap connection.">
		<cfset This.connection.disconnect() />	
	</cffunction>
	
	<!--- *********************************************************** --->
	<!--- search                                                      --->
	<!--- Performs an ldap search. Returns a raw array of results.    --->
	<!--- *********************************************************** --->
	<cffunction access="public" name="search" output="FALSE" returntype="query" hint="Performs an ldap search. Returns a raw array of results.">
		<cfargument name="filter" 				type="string" required="yes" 						hint="The distinguished name of the ldap user to connect with." />
		<cfargument name="attributes" 			type="string" required="yes" 						hint="A delimited list of attributes to retreive." />
		<cfargument name="base" 				type="string" required="no" 	default="" 			hint="The starting point for the ldap search." />
		<cfargument name="attributesDelimiter" 	type="string" required="no" 	default="," 		hint="The delimiter in the list of attributes." />
		<cfargument name="scope" 				type="string" required="no" 	default="SUBTREE" 	hint="The scope of the ldap search. " />
			<cfset var attributeArray 	= "" />
			<cfset var searchResults 	= "" />
			<cfset var ldapentry 		= "" />
			<cfset var resultsStruct 	= {} />
			<cfset var searchscope 		= "" />
		
				<!--- Handle Scoping --->
				<cfswitch expression="#arguments.scope#">
					<cfcase value="BASE">
						<cfset searchscope = This.connection.SCOPE_BASE />
					</cfcase>
					<cfcase value="ONE">
						<cfset searchscope = This.connection.SCOPE_ONE />
					</cfcase>
					<cfcase value="SUBORDINATESUBTREE">
						<cfset searchscope = This.connection.SCOPE_SUBORDINATESUBTREE />
					</cfcase>
					<cfdefaultcase>
						<cfset searchscope = This.connection.SCOPE_SUB />
					</cfdefaultcase>
				</cfswitch>
				
				<cfset attributeArray = createobject("java", "java.lang.String").init(arguments.attributes).split(arguments.attributesDelimiter)/>
				<cfset searchResults = This.connection.search(arguments.base,searchscope,arguments.filter,attributeArray, FALSE)/> 
								
				<cfset resultsQuery = resultsToQuery(attributeArray,searchResults) />
						
		<cfreturn resultsQuery /> 
	</cffunction>
				
	<!--- *********************************************************** --->
	<!--- update                                                      --->
	<!--- Performs an ldap update.                                    --->
	<!--- *********************************************************** --->
	<cffunction access="public" name="update" output="TRUE" returntype="void" hint="Performs an ldap update.">
		<cfargument name="userdn" 		type="string" required="yes" 						hint="The distinguished name of the ldap user to update." />
		<cfargument name="userdetails" 	type="struct" required="yes" 						hint="A structure containing the new values for the object." />
		<cfargument name="modifytype" 	type="string" required="no" 	default="replace" 	hint="How to handle multi-value attribute updates." />
 				
			<cfset var keysToStruct 	= StructKeyArray(arguments.userdetails) />
			<cfset var refArrayObj 		= createobject("java", "java.lang.reflect.Array") />
			<cfset var LDAPModClass 	= getJavaLoader().create("com.novell.ldap.LDAPModification") />
			<cfset var LDAPModArray 	= refArrayObj.newInstance(LDAPModClass.getClass(), ArrayLen(keysToStruct)) />
			<cfset var tempAttribute 	= "" />
			<cfset var tempCounter 		= 0 />
			<cfset var attributeType 	= "" />
				<!--- Loop through the structure of attributes and update the list. --->
				<cfset keysToStruct = StructKeyArray(arguments.userdetails) />
				<cfloop index = "i" from = "1" to = "#ArrayLen(keysToStruct)#">
					<!--- Handle that some values might be arrays. --->
					<cfif isArray(arguments.userdetails[keysToStruct[i]])>
						<cfset tempCounter 		= ArrayLen(arguments.userdetails[keysToStruct[i]]) />
						<cfset attributeType 	= "multi" />
					<cfelse>
						<cfset tempCounter 		= len(arguments.userdetails[keysToStruct[i]]) />
						<cfset attributeType 	= "single" />
					</cfif>	
					<!--- Handle NULLS --->
					<cfif tempCounter lt 1>
						<cfset tempAttribute 	= getJavaLoader().create("com.novell.ldap.LDAPAttribute").init(keysToStruct[i])/>
						<cfset tempModifcation 	= getJavaLoader().create("com.novell.ldap.LDAPModification").init(LDAPModClass.DELETE,tempAttribute)/>
					<cfelse>
						<cfset tempAttribute = getJavaLoader().create("com.novell.ldap.LDAPAttribute").init(keysToStruct[i],arguments.userdetails[keysToStruct[i]])/>
						<!--- If it's a multi-valued attribute --->
						<cfif Compare(attributeType, "multi")>
							<cfswitch expression="#arguments.modifytype#">
								<cfcase value="add">
									<cfset tempModifcation = getJavaLoader().create("com.novell.ldap.LDAPModification").init(LDAPModClass.ADD,tempAttribute)/>
								</cfcase>
								<cfcase value="delete">
									<cfset tempModifcation = getJavaLoader().create("com.novell.ldap.LDAPModification").init(LDAPModClass.DELETE,tempAttribute)/>
								</cfcase>
								<cfdefaultcase>
									<cfset tempModifcation = getJavaLoader().create("com.novell.ldap.LDAPModification").init(LDAPModClass.REPLACE,tempAttribute)/>
								</cfdefaultcase>
							</cfswitch>
						<cfelse>
							<cfset tempModifcation = getJavaLoader().create("com.novell.ldap.LDAPModification").init(LDAPModClass.REPLACE,tempAttribute)/>
						</cfif>
					</cfif>		
					<cfset refArrayObj.set(LDAPModArray, JavaCast("int",i-1), tempModifcation)/>
				</cfloop>
		<cfset This.connection.modify(arguments.userdn, LDAPModArray)/>				
	</cffunction>
	
	<!--- *********************************************************** --->
	<!--- resultsToQuery                                              --->
	<!--- Converts output from Java output to a ColdFusion query.     --->
	<!--- Logic stolen from http://www.d-ross.org/                    --->
	<!--- *********************************************************** --->
	<cffunction access="private" name="resultsToQuery" output="false" returntype="query" description="Converts output from Java output to a ColdFusion query.">
		<cfargument name="attributeArray" 	type="array" 	required="true" />
		<cfargument name="searchResults" 	type="any" 		required="true" />
			<cfset var rtnQry 	= queryNew(arraytolist(arguments.attributeArray)) />  
			<cfset var rtnEntry = 0 />
			<cfset var rc 		= 0 />
			<cfset var a 		= 0 />
			<cfset var temp 	= 0 />
				<cfloop condition="#arguments.searchResults.hasMore()#">
					<cftry>
						<cfset rtnEntry = arguments.searchResults.next() />
						<cfset rc = rc + 1 />
						<cfset queryAddRow(rtnQry,1) />
						<cfloop from="1" to="#arraylen(arguments.attributeArray)#" index="a">
							<cftry>
								<!--- This handles multivalue arrays and dn's --->
								<cfif arguments.attributeArray[a] eq "dn">
									<cfset querySetCell(rtnQry,arguments.attributeArray[a],rtnEntry.getDN()) />
								<cfelseif rtnEntry.getAttribute(arguments.attributeArray[a]).size() gt 1 >
									<cfset querySetCell(rtnQry,arguments.attributeArray[a],rtnEntry.getAttribute(arguments.attributeArray[a]).getStringValueArray(),rc) />
								<cfelse>
									<cfset querySetCell(rtnQry,arguments.attributeArray[a],rtnEntry.getAttribute(arguments.attributeArray[a]).getStringValue(),rc) />       
								</cfif>     
							<cfcatch>
								<!--- do nothing --->
							</cfcatch>
							</cftry>
						</cfloop>  	
						<!--- This try/catch prevents referal errors (resultcode 10) from mucking things up.  --->
						<!--- I'm sure there is a better way to handle than this but there you have it. --->
						<cfcatch type="any">
							<cfif not StructKeyExists(cfcatch,"ResultCode") or cfcatch.ResultCode neq 10>
								<cfrethrow />
							</cfif>
						</cfcatch>	
					</cftry>		 
				</cfloop>  
		<cfreturn rtnQry/>
	</cffunction>
	
</cfcomponent>