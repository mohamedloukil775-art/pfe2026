using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace PadelChampionship.Api.Data;

public class ApplicationDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
{
    public ApplicationDbContext CreateDbContext(string[] args)
    {
        // Keep design-time creation independent from web host startup.
        var defaultConnection = "server=localhost;port=3306;database=padel_championship;user=padel_app;password=PadelApp123!";

        var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
        optionsBuilder.UseMySql(defaultConnection, ServerVersion.AutoDetect(defaultConnection));

        return new ApplicationDbContext(optionsBuilder.Options);
    }
}