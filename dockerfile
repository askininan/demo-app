# Use the .NET runtime image for the final image
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS runtime

# Set the working directory for the runtime
WORKDIR /app

# Copy the published output from the Jenkins build
COPY ./publish .

# Set the entry point for the application
ENTRYPOINT ["dotnet", "HelloWorld.dll"]