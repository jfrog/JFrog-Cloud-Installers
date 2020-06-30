package tests

import io.restassured.RestAssured
import io.restassured.path.json.JsonPath
import io.restassured.response.Response
import org.hamcrest.Matchers
import org.testng.Reporter
import org.testng.annotations.BeforeTest
import org.testng.annotations.Test
import org.yaml.snakeyaml.Yaml
import steps.RepositorySteps

import java.time.LocalDate

import static org.hamcrest.Matchers.containsString
import static org.hamcrest.Matchers.containsStringIgnoringCase
import static org.hamcrest.Matchers.equalTo
import static org.hamcrest.Matchers.equalToIgnoringCase
import static org.hamcrest.Matchers.greaterThanOrEqualTo


class RepositoryTest extends RepositorySteps{
    Yaml yaml = new Yaml()
    def configFile = new File("./src/test/resources/testenv.yaml")
    def repoListHA = new File("./src/test/resources/repositories/CreateDefault.yaml")
    def repoListJCR = new File("./src/test/resources/repositories/CreateJCR.yaml")
    def artifact = new File("./src/test/resources/repositories/artifact.zip")
    def config = yaml.load(configFile.text)
    def artifactoryURL
    def username
    def password

    @BeforeTest(groups=["jcr", "pro"])
    def setUp() {
        artifactoryURL = config.artifactory.external_ip
        username = config.artifactory.rt_username
        password = config.artifactory.rt_password
        RestAssured.baseURI = "http://${artifactoryURL}/artifactory"
        RestAssured.authentication = RestAssured.basic(username, password);
        RestAssured.useRelaxedHTTPSValidation();
    }


    @Test(priority=1, groups=["pro"], testName = "Delete sample repositories")
    void deleteReposTest(){
        Response getRepoResponse = getRepos()
        JsonPath jsonPathEvaluator = getRepoResponse.jsonPath()
        List<String> repoNames = jsonPathEvaluator.getList("key", String.class)
        for (int i = 0; i < repoNames.size(); i ++){
            Response delete = deleteRepository(repoNames[i], username, password)
            delete.then().statusCode(200)
        }

        Reporter.log("- Delete sample HA repositories. All repositories were successfully deleted", true)
    }

    @Test(priority=1, groups=["jcr",], testName = "Delete sample repositories JCR")
    void deleteDefaultJCRReposTest(){
        Response getRepoResponse = getRepos()
        JsonPath jsonPathEvaluator = getRepoResponse.jsonPath()
        List<String> repoNames = jsonPathEvaluator.getList("key", String.class)
        for (int i = 0; i < repoNames.size(); i ++){
            Response delete = deleteRepository(repoNames[i], username, password)
            delete.then().statusCode(400).body("errors[0].message",
                    containsStringIgnoringCase("This REST API is available only in Artifactory Pro"))
        }

        Reporter.log("- Delete sample JCR repositories. " +
                "Verified - this REST API is available only in Artifactory Pro", true)
    }

    @Test(priority=2, groups=["pro"], testName = "Create a list of repositories for HA, specified in YAML file")
    void createDefaultHAReposTest(){
        def body
        def expectedMessage
        body = repoListHA
        expectedMessage = "383 changes to config merged successfully"
        Response response = createRepositories(body, username, password)
        response.then().assertThat().statusCode(200)
                .body(Matchers.hasToString(expectedMessage))
                .log().body()

        Reporter.log("- Create repositories for HA distribution. Successfully created", true)
    }

    @Test(priority=2, groups=["jcr"], testName = "Create a list of repositories for JCR, specified in YAML file")
    void createDefaultJCRReposTest(){
        def body
        def expectedMessage
        body = repoListJCR
        expectedMessage = "82 changes to config merged successfully"
        Response response = createRepositories(body, username, password)
        response.then().assertThat().statusCode(200)
                .body(Matchers.hasToString(expectedMessage))
                .log().body()

        Reporter.log("- Create repositories for JCR. Successfully created", true)
    }

    @Test(priority=3, groups=["pro"], testName = "Verify HA repositories were created successfully")
    void checkDefaultHAReposTest(){
        Response response = getRepos()
        def numberOfRepos = response.then().extract().path("size()")
        def expectedReposNumber = 84
        println("Number of created repositories is ${numberOfRepos}")
        response.then().assertThat().statusCode(200)
                .body("size()", greaterThanOrEqualTo(expectedReposNumber))

        Reporter.log("- Verify HA repos were created. ${numberOfRepos} repositories were created", true)
    }

    @Test(priority=3, groups=["jcr"], testName = "Verify JCR repositories were created successfully")
    void checkDefaultJCRReposTest(){
        Response response = getRepos()
        def numberOfRepos = response.then().extract().path("size()")
        def expectedReposNumber = 17
        response.then().assertThat().statusCode(200)
                .body("size()", greaterThanOrEqualTo(expectedReposNumber))

        Reporter.log("- Verify JCR repos were created. ${numberOfRepos} repositories were created", true)
    }

    /*@Test(priority=4, groups=["jcr","pro"], testName = "Create a directory in generic repo")
    void createDirectoryTest(){
        def repoName = "generic-dev-local"
        def directoryName = "test-directory/"
        Response response = createDirectory(repoName, directoryName)
        response.then().assertThat().statusCode(201)
                .body("repo", equalTo(repoName))
                .body("path", equalTo("/" + directoryName))
                .body("uri", equalTo("http://" + artifactoryURL + ":80/artifactory/" + repoName + "/" + directoryName))

        Reporter.log("- Create folder. Folder successfully created", true)
    }

    @Test(priority=5, groups=["jcr","pro"], testName = "Deploy file to generic repo")
    void deployArtifactToGenericTest(){
        def repoName = "generic-dev-local"
        def directoryName = "test-directory"
        def filename = "artifact.zip"
        Response response = deployArtifact(repoName, directoryName, artifact, filename)
        response.then().assertThat().statusCode(201)
                .body("repo", equalTo(repoName))
                .body("path", equalTo("/" + directoryName + "/" + filename))
                .body("downloadUri", equalTo("http://" + artifactoryURL + ":80/artifactory/" + repoName + "/"
                        + directoryName + "/" + filename))

        Reporter.log("- Deploy artifact. Artifact successfully deployed", true)
    }

    @Test(priority=6, groups=["jcr", "pro"], testName = "Get the artifact info")
    void getArtifactinfoTest(){
        def repoName = "generic-dev-local"
        def directoryName = "test-directory"
        def filename = "artifact.zip"
        Response response = getInfo(repoName, directoryName, artifact, filename)
        response.then().assertThat().statusCode(200)
                .body("repo", equalTo(repoName))
                .body("path", equalTo("/" + directoryName + "/" + filename))
                .body("downloadUri", equalTo("http://" + artifactoryURL + ":80/artifactory/" + repoName + "/"
                        + directoryName + "/" + filename))

        Reporter.log("- Get the artifact info. Artifact info is successfully returned", true)
    }*/

/*    @Test(priority=7, groups=["jcr", "pro"], testName = "Delete item")
    void deleteJCRItemTest(){
        def repoName = "generic-dev-local"
        def directoryName = "test-directory"
        def filename = "artifact.zip"
        Response response = deleteItem(repoName, directoryName, artifact, filename)
        response.then().assertThat().statusCode(204)

        Response verification = getInfo(repoName, directoryName, artifact, filename)
        verification.then().statusCode(404)
                .body("errors[0].message", equalToIgnoringCase("Unable to find item"))

        Reporter.log("- Delete item. File has been deleted successfully", true)
    }*/

    /*@Test(priority=8, groups=["pro"], testName = "Create support bundle")
    void createSupportBundleHATest(){
        def name = "Support Bundle"
        LocalDate startDate = LocalDate.now().minusDays(5)
        LocalDate endDate = LocalDate.now()
        Response response = createSupportBundle(name, startDate, endDate)
        response.then().assertThat().statusCode(200)
                .body("artifactory.bundle_url", containsString(artifactoryURL))

        Reporter.log("- Create support bundle. Successfully created", true)
    }*/

    @Test(priority=8, groups=["jcr"], testName = "Create support bundle")
    void createSupportBundleJCATest(){
        def name = "Support Bundle"
        LocalDate startDate = LocalDate.now().minusDays(5)
        LocalDate endDate = LocalDate.now()
        Response response = createSupportBundle(name, startDate, endDate)
        response.then().assertThat().statusCode(400)
                .body("errors[0].message",
                        containsStringIgnoringCase("This REST API is available only in Artifactory Pro"))

        Reporter.log("- Create support bundle, JCR. " +
                "Call is not supported in JCR version, error message is correct", true)
    }

    @Test(priority=9, groups=["pro"], testName = "Delete created repositories")
    void deleteDefaultReposTest(){
        Response getRepoResponse = getRepos()
        JsonPath jsonPathEvaluator = getRepoResponse.jsonPath()
        List<String> repoNames = jsonPathEvaluator.getList("key", String.class)
        for (int i = 0; i < repoNames.size(); i ++){
            Response delete = deleteRepository(repoNames[i], username, password)
            delete.then().statusCode(200)
        }

        Reporter.log("- Delete HA repositories. All repositories were successfully deleted", true)
    }

    @Test(priority=9, groups=["jcr",], testName = "Delete sample repositories JCR")
    void deleteJCRReposTest(){
        Response getRepoResponse = getRepos()
        JsonPath jsonPathEvaluator = getRepoResponse.jsonPath()
        List<String> repoNames = jsonPathEvaluator.getList("key", String.class)
        for (int i = 0; i < repoNames.size(); i ++){
            Response delete = deleteRepository(repoNames[i], username, password)
            delete.then().statusCode(400).body("errors[0].message",
                    containsStringIgnoringCase("This REST API is available only in Artifactory Pro"))
        }

        Reporter.log("- Delete sample JCR repositories. All repositories were successfully deleted", true)
    }

    @Test(priority=10, groups=["pro"], testName = "Verify repositories were deleted successfully")
    void checkReposAreDeleted(){
        Response response = getRepos()
        def numberOfRepos = response.then().extract().path("size()")
        def expectedReposNumber = 0
        response.then().assertThat().statusCode(200)
                .body("size()", equalTo(expectedReposNumber))

        Reporter.log("- Verify repo were deleted. ${numberOfRepos} repositories remain", true)
    }

    @Test(priority=11, groups=["pro"], testName = "Re-Create a list of repositories, for the next tests")
    void reCreateDefaultHAReposTest(){
        def body
        def expectedMessage
        body = repoListHA
        expectedMessage = "383 changes to config merged successfully"
        Response response = createRepositories(body, username, password)
        response.then().assertThat().statusCode(200)
                .body(Matchers.hasToString(expectedMessage))
                .log().body()

        Reporter.log("- Re-create repositories for HA distribution. Successfully created", true)
    }

    @Test(priority=12, groups=["jcr"], testName = "Re-Create a list of repositories, for the next tests")
    void reCreateDefaultJCRReposTest(){
        def body
        def expectedMessage
        body = repoListJCR
        expectedMessage = "82 changes to config merged successfully"
        Response response = createRepositories(body, username, password)
        response.then().assertThat().statusCode(200)
                .body(Matchers.hasToString(expectedMessage))
                .log().body()

        Reporter.log("- Re-create repositories for JCR distribution. Successfully created", true)
    }

/*    @Test(priority=13, groups=["jcr","pro"], testName = "Create a directory in generic repo")
    void reCreateDirectoryTest(){
        def repoName = "generic-dev-local"
        def directoryName = "test-directory/"
        Response response = createDirectory(repoName, directoryName)
        response.then().assertThat().statusCode(201)
                .body("repo", equalTo(repoName))
                .body("path", equalTo("/" + directoryName))
                .body("uri", equalTo("http://" + artifactoryURL + ":80/artifactory/" + repoName + "/" + directoryName))

        Reporter.log("- Create folder. Folder successfully created", true)
    }*/

/*    @Test(priority=14, groups=["jcr","pro"], testName = "Deploy file to generic repo")
    void reDeployArtifactToGenericTest(){
        def repoName = "generic-dev-local"
        def directoryName = "test-directory"
        def filename = "artifact.zip"
        Response response = deployArtifact(repoName, directoryName, artifact, filename)
        response.then().assertThat().statusCode(201)
                .body("repo", equalTo(repoName))
                .body("path", equalTo("/" + directoryName + "/" + filename))
                .body("downloadUri", equalTo("http://" + artifactoryURL + ":80/artifactory/" + repoName + "/"
                        + directoryName + "/" + filename))

        Reporter.log("- Deploy artifact. Artifact successfully deployed", true)
    }*/


}
