# Multi-stage build using hardened Azure Linux 3.0 & .NET 10 runtime
FROM mcr.microsoft.com/dotnet/sdk:10.0-azurelinux3.0 AS build
WORKDIR /src

# Copy NuGet configuration enforcing internal Nexus proxy & signature validation
COPY ["docker/NuGet.config", "./NuGet.config"]
COPY ["PaymentService.csproj", "./"]
RUN dotnet restore "PaymentService.csproj" --configfile NuGet.config

COPY . .
RUN dotnet publish "PaymentService.csproj" -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0-azurelinux3.0 AS final
WORKDIR /app

# Enforce FIPS 140-3 OpenSSL SymCrypt provider & backward compatibility roll-forward
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    DOTNET_ROLL_FORWARD=Major \
    OPENSSL_CONF=/etc/pki/tls/openssl.cnf \
    ASPNETCORE_URLS=http://+:8080

COPY --from=build /app/publish .

# Run as non-root container user (PCI-DSS hardening requirement)
USER app
EXPOSE 8080

ENTRYPOINT ["dotnet", "PaymentService.dll"]
