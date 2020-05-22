package tests

import io.restassured.RestAssured
import io.restassured.response.Response
import org.hamcrest.Matchers
import org.junit.Assert
import org.testng.Reporter
import org.testng.annotations.BeforeSuite
import org.testng.annotations.Test
import org.yaml.snakeyaml.Yaml
import steps.SecuritytSteps


class SecurityTest extends SecuritytSteps{

    Yaml yaml = new Yaml()
    def configFile = new File("./src/test/resources/testenv.yaml")
    def config = yaml.load(configFile.text)
    def artifactoryURL
    def distribution
    def username
    def password

    @BeforeSuite(groups=["jcr","pro"])
    def setUp() {
        artifactoryURL = config.artifactory.external_ip
        distribution = config.artifactory.distribution
        username = config.artifactory.rt_username
        password = config.artifactory.rt_password
        RestAssured.baseURI = "http://${artifactoryURL}/artifactory"
        RestAssured.authentication = RestAssured.basic(username, password);
        RestAssured.useRelaxedHTTPSValidation();
    }

    @Test(priority=1, groups=["pro"], dataProvider = "users", testName = "Create users")
    void createUsersTest(usernameRt, emailRt, passwordRt){
        Response response = createUser(usernameRt, emailRt, passwordRt)
        response.then().statusCode(201)

        Reporter.log("- Create users. User ${usernameRt} created successfully", true)
    }

    @Test(priority=2, groups=["pro"], dataProvider = "users", testName = "Verify users were created successfully")
    void verifyUsersTest(usernameRt, emailRt, passwordRt){
        Response response = getUserDetails(usernameRt)
        response.then().statusCode(200).
                body("name", Matchers.equalTo(usernameRt)).
                body("email",  Matchers.equalTo(emailRt)).
                body("admin",  Matchers.equalTo(false)).
                body("groups[0]",  Matchers.equalTo("readers"))

        Reporter.log("- Verify created users. User ${usernameRt} was successfully verified", true)
    }

    @Test(priority=3, groups=["pro"], dataProvider = "users", testName = "Generate API keys")
    void generateAPIKeysTest(usernameRt, emailRt, passwordRt) {
        Response createKey = generateAPIKey(usernameRt, passwordRt)
        def errorMessage = createKey.then().extract().path("error")
        if (errorMessage == null) {
            def key = createKey.then().extract().path("apiKey")
            Response getKey = getAPIKey(usernameRt, passwordRt)
            def keyVerification = getKey.then().extract().path("apiKey")
            Assert.assertTrue(key == keyVerification)
            Reporter.log("- Generate API keys. Key for ${usernameRt} created successfully", true)
        } else if (errorMessage.toString().contains("Api key already exists for user:")){
            Reporter.log("- Generate API keys. Key for ${usernameRt} already exists, skipped", true)
        }
    }

    @Test(priority=4, groups=["pro"], dataProvider = "users", testName = "Re-generate API keys")
    void regenerateAPIKeysTest(usernameRt, emailRt, passwordRt){
        Response regenerated = regenerateAPIKey(usernameRt, passwordRt)
        regenerated.then().statusCode(200)
        def key = regenerated.then().extract().path("apiKey")
        Response getKey = getAPIKey(usernameRt, passwordRt)
        getKey.then().statusCode(200)
        def keyVerification = getKey.then().extract().path("apiKey")
        Assert.assertTrue(key == keyVerification)

        Reporter.log("- Re-generate API keys. Key for ${usernameRt} re-generated successfully", true)
    }

    @Test(priority=5, groups=["pro"], dataProvider = "groups", testName = "Create a group")
    void createGroupTest(groupName){
        Response create = createGroup(groupName)
        create.then().statusCode(201)

        Response get = getGroup(groupName)
        get.then().statusCode(200)
        def name = get.then().extract().path("name")
        def adminPrivileges = get.then().extract().path("adminPrivileges")
        Assert.assertTrue(name == groupName)
        Assert.assertTrue(adminPrivileges == false)

        Reporter.log("- Create group. Group ${groupName} was successfully created", true)
    }

    @Test(priority=6, groups=["pro"], testName = "Create and verify permissions")
    void createPermissionsTest(){
        def permissionName = "testPermission"
        def repository = "ANY"
        def user1 = "testuser0"
        def user2 = "testuser1"
        def group1 = "test-group-0"
        def group2 = "test-group-1"
        def action1 = "read"
        def action2 = "write"
        def action3 = "manage"
        Response create = createPermissions(permissionName, repository, user1, user2,
        group1, group2, action1, action2, action3)
        create.then().statusCode(200)

        Response get = getPermissions(permissionName)
        get.then().statusCode(200)
        Assert.assertTrue(permissionName == get.then().extract().path("name"))
        Assert.assertTrue(repository == get.then().extract().path("repo.repositories[0]"))
        Assert.assertTrue(action1 == get.then().extract().path("repo.actions.users.${user1}[0]"))
        Assert.assertTrue(action2 == get.then().extract().path("repo.actions.users.${user1}[1]"))
        Assert.assertTrue(action3 == get.then().extract().path("repo.actions.users.${user1}[2]"))
        Assert.assertTrue(action1 == get.then().extract().path("repo.actions.users.${user2}[0]"))
        Assert.assertTrue(action2 == get.then().extract().path("repo.actions.users.${user2}[1]"))
        Assert.assertTrue(action3 == get.then().extract().path("repo.actions.users.${user2}[2]"))
        Assert.assertTrue(action1 == get.then().extract().path("repo.actions.groups.${group1}[0]"))
        Assert.assertTrue(action2 == get.then().extract().path("repo.actions.groups.${group2}[1]"))
        Assert.assertTrue(action1 == get.then().extract().path("repo.actions.groups.${group2}[0]"))
        Assert.assertTrue(action2 == get.then().extract().path("repo.actions.groups.${group2}[1]"))

        Reporter.log("- Create permissions. Permissions successfully created and verified", true)
    }

    @Test(priority=7, groups=["pro"], testName = "Delete permissions")
    void deletePermissionsTest(){
        def permissionName = "testPermission"
        Response delete = deletePermissions(permissionName)
        delete.then().statusCode(200)
        Reporter.log("- Delete permissions. User ${permissionName} has been removed successfully", true)
    }

    @Test(priority=8, groups=["pro"], dataProvider = "users", testName = "Delete non-default users")
    void deleteUserTest(usernameRt, email, passwordRt){
        Response delete = deleteUser(usernameRt)
        delete.then().statusCode(200).body(Matchers.containsString("${usernameRt}"))
        Reporter.log("- Delete user. User ${usernameRt} has been removed successfully", true)
    }

    @Test(priority=9, groups=["pro"], dataProvider = "groups", testName = "Delete non-default groups")
    void deleteGroupTest(groupName){
        Response delete = deleteGroup(groupName)
        delete.then().statusCode(200).body(Matchers.containsString("${groupName}"))
        Reporter.log("- Delete group. Group ${groupName} has been removed successfully", true)
    }

}
