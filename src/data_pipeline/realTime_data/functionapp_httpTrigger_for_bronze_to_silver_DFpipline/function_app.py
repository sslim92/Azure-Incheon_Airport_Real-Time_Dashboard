import azure.functions as func
from azure.identity import ClientSecretCredential
from azure.mgmt.datafactory import DataFactoryManagementClient
import logging
import os

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

@app.route(route="http_trigger")
def http_trigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    # 환경 변수에서 인증 정보 및 리소스 정보 가져오기
    tenant_id = os.environ.get('AZURE_TENANT_ID')
    client_id = os.environ.get('AZURE_CLIENT_ID')
    client_secret = os.environ.get('AZURE_CLIENT_SECRET')
    subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
    resource_group = os.environ.get('RESOURCE_GROUP')
    data_factory_name = os.environ.get('DATA_FACTORY_NAME')

    # 인증 객체 생성
    credentials = ClientSecretCredential(tenant_id, client_id, client_secret)
    adf_client = DataFactoryManagementClient(credentials, subscription_id)

    # 파이프라인 실행
    #run_response = adf_client.pipelines.create_run(
    #    resource_group, data_factory_name, 'rest_api_test_PL', parameters={}
    #)

    # Stream Analytics 작업으로 부터 소스 데이터 수신
    req_body = req.get_json()
    logging.info(f"수신된 데이터: {req_body}")

    # 소스 데이터에 따라서 지정된 파이프라인 실행
    for event in req_body:
        # Stream Analytics 쿼리에서 지정한 'message' 필드를 가져오기
        message = event.get('message')

        if message == 'api_bronze_departure_weather':
            logging.info("api_bronze_departure_weather 이벤트 처리 중...")
            
            run_response = adf_client.pipelines.create_run(
                resource_group, data_factory_name, 'api_bronze_to_silver_departure_weather', parameters={}
            )

        elif message == 'api_bronze_parkinglot':
            logging.info("api_bronze_parkinglot 이벤트 처리 중...")

            run_response = adf_client.pipelines.create_run(
                resource_group, data_factory_name, 'api_bronze_to_silver_parkinglot', parameters={}
            )

        elif message == 'api_bronze_indoorair_quality':
            logging.info("api_bronze_indoorair_quality 이벤트 처리 중...")

            run_response = adf_client.pipelines.create_run(
                resource_group, data_factory_name, 'api_bronze_to_silver_indoorair_quality', parameters={}
            )

        elif message == 'api_bronze_area_weather_data':
            logging.info("api_bronze_area_weather_data 이벤트 처리 중...")

            run_response = adf_client.pipelines.create_run(
                resource_group, data_factory_name, 'api_silver_area_weather_data_PL', parameters={}
            )
            logging.info(f"파이프라인 실행 ID: {run_response.run_id}")

        elif message == 'api_bronze_departure_forecast':
            logging.info("api_bronze_departure_forecast 이벤트 처리 중...")

            run_response = adf_client.pipelines.create_run(
                resource_group, data_factory_name, 'bronze_to_slilver_departure_forecast', parameters={}
            )

        else:
            logging.warning(f"알 수 없는 이벤트: {message}")

    #return func.HttpResponse(f"Pipeline run started. Run ID: {run_response.run_id}", status_code=200)
    return func.HttpResponse("실행 완료.", status_code=200)