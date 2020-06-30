package tests

import io.restassured.RestAssured
import io.restassured.response.Response
import org.testng.Assert
import org.testng.Reporter
import org.testng.annotations.BeforeSuite
import org.testng.annotations.BeforeTest
import org.testng.annotations.Test
import org.yaml.snakeyaml.Yaml
import steps.XraySteps

import java.time.LocalDate

import static org.hamcrest.Matchers.containsStringIgnoringCase
import static org.hamcrest.Matchers.emptyArray
import static org.hamcrest.Matchers.equalTo
import static org.hamcrest.Matchers.hasItem
import static org.hamcrest.Matchers.is
import static org.hamcrest.Matchers.isA
import static org.hamcrest.Matchers.not
import static org.hamcrest.Matchers.notNullValue
import static org.hamcrest.Matchers.nullValue


class XrayTest extends XraySteps{

    Yaml yaml = new Yaml()
    def configFile = new File("./src/test/resources/testenv.yaml")
    def config = yaml.load(configFile.text)
    def artifactoryURL
    def distribution
    def username
    def password
    def randomIndex
    def policyName
    def watchName

    @BeforeSuite(groups=["xray"])
    def setUp() {
        artifactoryURL = config.artifactory.external_ip
        distribution = config.artifactory.distribution
        username = config.artifactory.rt_username
        password = config.artifactory.rt_password
        RestAssured.authentication = RestAssured.basic(username, password)
        RestAssured.useRelaxedHTTPSValidation()
        Random random = new Random()
        randomIndex = random.nextInt(10000000)
        policyName = "security_policy_${randomIndex}"
        watchName = "all-repositories_${randomIndex}"
    }
    @BeforeTest(groups=["xray"])
    def testSetUp() {
        RestAssured.baseURI = "http://${artifactoryURL}/xray/api"
    }

    @Test(priority=1, groups=["xray"], dataProvider = "issueEvents", testName = "Create Issue Event")
    void createIssueEventTest(issueID, cve, summary, description){
        Response create = createIssueEvent(issueID+randomIndex, cve, summary, description, username, password)
        create.then().statusCode(201)
        Response get = getIssueEvent(issueID+randomIndex, username, password)
        get.then().statusCode(200)
        def issueIDverification = get.then().extract().path("id")
        def cveVerification = get.then().extract().path("source_id")
        def summaryVerification = get.then().extract().path("summary")
        def descriptionVerification = get.then().extract().path("description")
        Assert.assertTrue(issueID+randomIndex == issueIDverification)
        Assert.assertTrue(cve == cveVerification)
        Assert.assertTrue(summary == summaryVerification)
        Assert.assertTrue(description == descriptionVerification)

        Reporter.log("- Create issue event. Issue event with ID ${issueID+randomIndex} created and verified successfully", true)
    }

    @Test(priority=2, groups=["xray"], dataProvider = "issueEvents", testName = "Update Issue Event",
            dependsOnMethods = "createIssueEventTest")
    void updateIssueEventTest(issueID, cve, summary, description){
        cve = "CVE-2017-0000000"
        summary = "Updated"
        description = "Updated"
        Response update = updateIssueEvent(issueID+randomIndex, cve, summary, description, username, password)
        update.then().statusCode(200)
        Response get = getIssueEvent(issueID+randomIndex, username, password)
        get.then().statusCode(200)
        def cveVerification = get.then().extract().path("source_id")
        def summaryVerification = get.then().extract().path("summary")
        def descriptionVerification = get.then().extract().path("description")
        Assert.assertTrue(cve == cveVerification)
        Assert.assertTrue(summary == summaryVerification)
        Assert.assertTrue(description == descriptionVerification)

        Reporter.log("- Update issue event. Issue event with ID ${issueID+randomIndex} updated and verified successfully", true)
    }

    @Test(priority=3, groups=["xray"], testName = "Create policy")
    void createPolicyTest(){
        Response create = createPolicy(policyName, username, password)
        create.then().statusCode(201)

        Response get = getPolicy(policyName, username, password)
        get.then().statusCode(200)
        def policyNameVerification = get.then().extract().path("name")
        Assert.assertTrue(policyName == policyNameVerification)

        Reporter.log("- Create policy. Policy with name ${policyName} created and verified successfully", true)
    }

    @Test(priority=4, groups=["xray"], testName = "Update policy", dependsOnMethods = "createPolicyTest")
    void updatePolicyTest(){
        def description = "Updated description"
        Response update = updatePolicy(policyName, description, username, password)
        update.then().statusCode(200)

        Response get = getPolicy(policyName, username, password)
        get.then().statusCode(200)
        def descriptionVerification = get.then().extract().path("description")
        Assert.assertTrue(description == descriptionVerification)

        Reporter.log("- Update policy. Policy with name ${policyName} updated and verified successfully", true)
    }

    @Test(priority=4, groups=["xray"], testName = "Get policies")
    void getPoliciesTest(){
        Response response = getPolicies(username, password)
        response.then().statusCode(200)
                .body("name", notNullValue())
                .body("type", notNullValue())
                .body("description", notNullValue())
                .body("author", notNullValue())
                .body("rules", notNullValue())
                .body("created", notNullValue())
                .body("modified", notNullValue())
        def policies = response.then().extract().path("name")
        Reporter.log("- Get policies. Policies list is returned successfully. " +
                "Policies returned: ${policies}", true)
    }

    @Test(priority=5, groups=["xray"], testName = "Create watch for the repositories", dependsOnMethods = "createPolicyTest")
    void createWatchTest(){
        Response create = createWatchEvent(watchName, policyName, username, password)
        create.then().statusCode(201)
                .body("info",
                equalTo("Watch has been successfully created"))

        Response get = getWatchEvent(watchName, username, password)
        get.then().statusCode(200)
                .body("general_data.name", equalTo((watchName).toString()))

        Reporter.log("- Create watch. Watch with name ${watchName} has been created and verified successfully", true)
    }

    @Test(priority=6, groups=["xray"], testName = "Update watch for the repositories", dependsOnMethods = "createWatchTest")
    void updateWatchTest(){
        def description = "Updated watch"
        Response create = updateWatchEvent(watchName, description, policyName, username, password)
        create.then().statusCode(200)
                .body("info",
                        equalTo("Watch was successfully updated"))

        Response get = getWatchEvent(watchName, username, password)
        get.then().statusCode(200)
                .body("general_data.description", equalTo(description))

        Reporter.log("- Update watch. Watch with name ${watchName} has been updated and verified successfully", true)
    }

    @Test(priority=7, groups=["xray"], testName = "Assign policy to watches")
    void assignPolicyToWatchTest(){
        Response response = assignPolicy(watchName, policyName, username, password)
        response.then().statusCode(200)
                .body("result.${watchName}",
                        equalTo("Policy assigned successfully to Watch"))

        Reporter.log("- Assign policy to watch. Policy assigned successfully to Watch", true)
    }

    @Test(priority=8, groups=["xray"], testName = "Delete watch")
    void deleteWatchTest(){
        Response response = deleteWatchEvent(watchName, username, password)
        response.then().statusCode(200)
                .body("info",
                        equalTo("Watch was deleted successfully"))

        Reporter.log("- Delete watch. Watch ${watchName} has been successfully deleted", true)
    }

    @Test(priority=9, groups=["xray"], testName = "Delete policy")
    void deletePolicyTest(){

        Response response = deletePolicy(policyName, username, password)
        response.then().statusCode(200)
                .body("info",
                        equalTo(("Policy ${policyName} was deleted successfully").toString()))

        Reporter.log("- Delete policy. Policy ${policyName} has been successfully deleted", true)
    }

/*    @Test(priority=10, groups=["xray"], testName = "Start scan")
    void startScanTest(){
        def artifactPath = "default/generic-dev-local/test-directory/artifact.zip"
        Response getSha = artifactSummary(username, password, artifactPath)
        def componentID = getSha.then().extract().path("artifacts[0].licenses[0].components[0]")

        Response scan = startScan(username, password, componentID)
        scan.then().statusCode(200)
                .body("info",
                        equalTo(("Scan of artifact is in progress").toString()))

        Reporter.log("- Start scan. Scan of ${componentID} has been started successfully", true)
    }*/

    @Test(priority=11, groups=["xray"], testName = "Create and get integration configuration")
    void integrationConfigurationTest(){
        def vendorName = "vendor_${randomIndex}"
        Response post = addtIntegrationConfiguration(username, password, vendorName)
        post.then().statusCode(200)

        Response get = getIntegrationConfiguration(username, password)
        int bodySize = get.body().jsonPath().getList(".").size()
        get.then().statusCode(200)
                .body("[" + (bodySize-1) + "].vendor", equalTo(vendorName.toString()))

        Reporter.log("- Integration configuration. " +
                "Configuration for vendor ${vendorName} has been successfully added and verified", true)
    }

    @Test(priority=12, groups=["xray"], testName = "Enable TLS for RabbitMQ")
    void enableTLSRabbitMQTest(){
        File body = new File("./src/test/resources/enableRabbitMQ.json")
        Response post = postSystemParameters(username, password, body)
        post.then().statusCode(200)

        Response get = getSystemParameters(username, password)
        get.then().statusCode(200).body("enableTlsConnectionToRabbitMQ", equalTo(true))

        Reporter.log("- Enable TLS for RabbitMQ. TLS for RabbitMQ has been successfully enabled and verified", true)
    }

    @Test(priority=13, groups=["xray"], testName = "Get binary manager")
    void getBinaryManagerTest(){
        Response response = getBinaryManager(username, password)
        response.then().statusCode(200)
                .body("binMgrId", equalTo("default"))
                .body("license_valid", equalTo(true))
                .body("binMgrId", equalTo("default"))
        def version = response.then().extract().path("version")

        Reporter.log("- Get binary manager. Binary manager is verified, connected RT version: ${version}", true)
    }

    @Test(priority=14, groups=["xray"], testName = "Get repo indexing configuration")
    void getIndexingConfigurationTest(){
        Response response = getIndexingConfiguration(username, password)
        response.then().statusCode(200)
                .body("bin_mgr_id", equalTo("default"))
                .body("indexed_repos.name", hasItem("generic-dev-local"))

        Reporter.log("- Get repo indexing configuration.", true)
    }

    @Test(priority=15, groups=["xray"], testName = "Update repo indexing configuration")
    void updateIndexingConfigurationTest(){
        Response response = updateIndexingConfiguration(username, password)
        response.then().statusCode(200)
                .body("info", equalTo("Repositories list has been successfully sent to Artifactory"))

        Reporter.log("- Update repo indexing configuration. Successfully updated", true)
    }

    //    Force reindex test, add in latest versions of X-ray

/*    @Test(priority=16, groups=["xray"], testName = "Get artifact summary")
    void artifactSummaryTest(){
        def artifactPath = "default/generic-dev-local/test-directory/artifact.zip"
        Response post = artifactSummary(username, password, artifactPath)
        post.then().statusCode(200)
                .body("artifacts[0].general.path", equalTo(artifactPath))

        Reporter.log("- Get artifact summary. Artifact summary has been returned successfully", true)
    }*/

    @Test(priority=17, groups=["xray"], testName = "Create support bundle")
    void createSupportBundleTest(){
        def name = "Support Bundle"
        LocalDate startDate = LocalDate.now().minusDays(5)
        LocalDate endDate = LocalDate.now()
        Response response = createSupportBundle(username, password, name, startDate, endDate)
        def bundle_url = response.then().extract().path("artifactory.bundle_url")
        if ((bundle_url.toString()).contains(artifactoryURL)) {
            Reporter.log("- Create support bundle. Successfully created using X-ray API", true)
        } else if (((bundle_url.toString()).contains("localhost"))){
            Reporter.log("- Create support bundle. Created with a bug, localhost instead of the hostname", true)
        }
    }

    @Test(priority=18, groups=["xray"], testName = "Get system monitoring status")
    void getSystemMonitoringTest(){
        Response response = getSystemMonitoringStatus(username, password)
        response.then().statusCode(200)

        Reporter.log("- Get system monitoring status. Data returned successfully", true)
    }

    @Test(priority=19, groups=["xray"], testName = "X-ray ping request")
    void xrayPingRequestTest(){
        Response response = xrayPingRequest(username, password)
        response.then().statusCode(200)
                .body("status", equalTo("pong"))

        Reporter.log("- Get system monitoring status. Data returned successfully", true)
    }

    @Test(priority=20, groups=["xray"], testName = "X-ray version")
    void xrayGetVersionTest(){
        Response response = xrayGetVersion(username, password)
        response.then().statusCode(200)
                .body("xray_version", notNullValue())
                .body("xray_revision", notNullValue())
        def version = response.then().extract().path("xray_version")
        def revision = response.then().extract().path("xray_revision")

        Reporter.log("- Get X-ray version. Version: ${version}, revision: ${revision}", true)
    }




}




