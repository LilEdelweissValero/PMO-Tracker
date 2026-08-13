# Use an append-only Project event ledger

Project mutations append a typed event and update a current-state projection in one PostgreSQL transaction. The projection keeps routine screens simple and fast, while the event ledger enables Effective and Recorded As-of Views, backdated entry, ownership-duration reconstruction, and non-destructive correction; updating current rows alone would make those historical answers unreliable, while deriving every current screen exclusively from events would add needless complexity for this small application.
