import { APIGatewayProxyHandler } from 'aws-lambda';

export const handler: APIGatewayProxyHandler = async (event, context) => {
  console.log("EVENT: \n" + JSON.stringify(event, null, 2));
  
  return {
    statusCode: 200,
    body: 'DONE',
  };
}