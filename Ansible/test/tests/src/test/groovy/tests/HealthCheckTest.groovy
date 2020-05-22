package tests

import io.restassured.RestAssured
import io.restassured.path.json.JsonPath
import io.restassured.response.Response
import org.hamcrest.Matchers
import org.testng.Reporter
import org.testng.annotations.BeforeSuite
import org.testng.annotations.Test
import steps.RepositorySteps
import org.yaml.snakeyaml.Yaml
import utils.Shell

class HealthCheckTest extends RepositorySteps{
    Yaml yaml = new Yaml()
    def configFile = new File("./src/test/resources/testenv.yaml")
    def config = yaml.load(configFile.text)
    def artifactoryURL


    @BeforeSuite(alwaysRun = true)
    def setUp() {
        artifactoryURL = config.artifactory.external_ip
        RestAssured.baseURI = "http://${artifactoryURL}/artifactory"
    }


    @Test(priority=0, groups="common", testName = "Health check for all 4 services")
    void healthCheckTest(){
        Response response = getHealthCheckResponse(artifactoryURL)
        response.then().assertThat().statusCode(200).
                body("router.state", Matchers.equalTo("HEALTHY"))

        int bodySize = response.body().jsonPath().getList("services").size()
        for (int i = 0; i < bodySize; i++) {
            JsonPath jsonPathEvaluator = response.jsonPath()
            String serviceID = jsonPathEvaluator.getString("services[" + i + "].service_id")
            String nodeID = jsonPathEvaluator.getString("services[" + i + "].node_id")
            response.then().
                    body("services[" + i + "].state", Matchers.equalTo("HEALTHY"))

            Reporter.log("- Health check. Service \"" + serviceID + "\" on node \"" + nodeID + "\" is healthy", true)
        }

    }

    @Test(priority=1, groups=["ping","common"], testName = "Ping (In HA 200 only when licences were added)")
    void pingTest() {
        Response response = ping()
        response.then().assertThat().statusCode(200).
                body(Matchers.hasToString("OK"))
        Reporter.log("- Ping test. Service is OK", true)
    }



}
