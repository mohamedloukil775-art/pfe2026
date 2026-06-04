using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PadelChampionship.Api.Data;
using PadelChampionship.Api.Models;

namespace PadelChampionship.Api.Controllers;

[ApiController]
[Route("api/storage")]
public class StorageController(ApplicationDbContext db) : ControllerBase
{
    [HttpGet("{key}")]
    public async Task<IActionResult> Get(string key)
    {
        var entry = await db.StorageEntries.FindAsync(key);
        if (entry == null) return NotFound();
        return Ok(new { value = entry.Value });
    }

    [HttpPost("{key}")]
    public async Task<IActionResult> Set(string key, [FromBody] StorageRequest req)
    {
        var entry = await db.StorageEntries.FindAsync(key);
        if (entry == null)
            db.StorageEntries.Add(new StorageEntry { Key = key, Value = req.Value });
        else
            entry.Value = req.Value;

        await db.SaveChangesAsync();
        return Ok();
    }

    [HttpDelete("{key}")]
    public async Task<IActionResult> Delete(string key)
    {
        var entry = await db.StorageEntries.FindAsync(key);
        if (entry != null)
        {
            db.StorageEntries.Remove(entry);
            await db.SaveChangesAsync();
        }
        return Ok();
    }
}

public record StorageRequest(string Value);
