defmodule ChatApi.AwsTest do
  use ChatApi.DataCase

  alias ChatApi.Aws

  describe "aws" do
    test "validate_config/0 validates that all the environment variables are set" do
      # Not sure the best way to test environment variables...
      validation =
        case Aws.Config.validate() do
          {:ok,
           %{
             aws_key_id: _aws_key_id,
             aws_secret_key: _aws_secret_key,
             bucket_name: _bucket_name,
             region: _region
           }} ->
            true

          {:error, :invalid_aws_config, _} ->
            true

          _ ->
            false
        end

      assert validation
    end

    test "generate_unique_filename/1 generates a unique filename with a uuid" do
      filename = "test-file.jpg"
      uniq_1 = Aws.generate_unique_filename(filename)
      uniq_2 = Aws.generate_unique_filename(filename)

      assert uniq_1 != uniq_2
    end

    test "generate_unique_filename/1 replaces spaces with dashes if necessary" do
      filename = "test file.jpg"
      assert Aws.generate_unique_filename(filename) =~ "-test-file.jpg"
    end

    test "get_file_url/2 formats the s3 file url" do
      filename = "test-file.jpg"
      bucket = "papercups"

      assert Aws.get_file_url(filename, bucket) ==
               "https://papercups.s3.amazonaws.com/test-file.jpg"
    end
  end

  describe "lambda" do
    test "get" do
      function_name = "test"
      %{"Configuration" => configuration} = Aws.get_function(function_name)
      assert configuration["FunctionName"] == function_name
    end

    test "create" do
      %{"FunctionName" => function_name} =
        Aws.create_function(
          Path.absname("test/assets/test.zip"),
          "somefile-name",
          "test/index.handler"
        )

      %{"Configuration" => configuration} = Aws.get_function(function_name)
      assert function_name == configuration["FunctionName"]
      result = Aws.invoke_function(function_name, %{"test" => "test"})

      delete_function = Aws.delete_function(function_name)
    end

    test "code upload" do
      code = """
      exports.handler = async (event) => {
        // TODO implement
        const response = {
            statusCode: 200,
            body: JSON.stringify(event),
        };
        return response;
      };

      """
      function_name = Aws.generate_unique_filename("test_function_name")
      result  = Aws.code_upload(code, function_name)
      %{"body" => body, "statusCode" => statusCode} = Aws.invoke_function(function_name, %{"hello" => "world"})
      assert body =~ "hello"
      assert body =~ "world"

      updated_code = """
      exports.handler = async (event) => {
        // TODO implement
        const response = {
            statusCode: 200,
            body: JSON.stringify({"updated": "function"}),
        };
        return response;
      };
      """

      updated_function = Aws.update_function(updated_code, function_name)
      %{"body" => body, "statusCode" => statusCode} = Aws.invoke_function(function_name, %{"hello" => "world"})
      assert body =~ "updated"
      assert body =~ "function"
    end

    test "execute" do
    end

    test "update" do
    end

    test "delete" do
    end
  end
end
