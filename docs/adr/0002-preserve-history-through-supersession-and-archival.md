# Preserve history through supersession and archival

Incorrect Project events are corrected by a replacement that supersedes the original, and Projects are archived rather than deleted. This keeps prior records available for audit and As-of Views while allowing the current operational view to reflect corrections; destructive editing would make historical results silently change or become impossible to reproduce.

Archived Projects remain selectable under the same read policy so audit and historical reports can resolve them. Operational queues, lists, and default searches must explicitly filter `archived_at is null`; an archived-records mode must opt in to including them. Archival therefore changes operational visibility without weakening historical access.
