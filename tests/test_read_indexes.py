"""Local SQLite regression: results and query plans, no remote D1 reads.
Run: python3 -m unittest discover -s tests
"""
import pathlib
import sqlite3
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class ReadIndexesTest(unittest.TestCase):
    def test_covering_searches_preserve_results(self):
        db = sqlite3.connect(':memory:')
        for table, amount in [('delegated_snapshots', 'delegated_lamports'),
                              ('token_supply_snapshots', 'token_supply_lamports')]:
            db.execute(f'CREATE TABLE {table} (chain TEXT, mint TEXT, ts INTEGER, '
                       f'slot INTEGER, {amount} INTEGER, PRIMARY KEY(chain,mint,slot))')
            db.executemany(f'INSERT INTO {table} VALUES (?,?,?,?,?)',
                           [('sol', f'mint-{m}', i * 1000, i, 100)
                            for m in range(5) for i in range(1000)])
        queries = [
            ("SELECT ts FROM token_supply_snapshots WHERE chain=? ORDER BY ts DESC LIMIT 1",
             ('sol',), 'idx_supply_chain_ts'),
            *[(f'SELECT slot FROM {table} WHERE chain=? AND mint=? AND ts<=? '
               'ORDER BY ts DESC LIMIT 1', ('sol', 'mint-2', 500000), index)
              for table, index in [('delegated_snapshots', 'idx_delegated_chain_mint_ts_slot'),
                                   ('token_supply_snapshots', 'idx_supply_chain_mint_ts_slot')]],
        ]
        before = [db.execute(sql, args).fetchall() for sql, args, _ in queries]
        db.executescript((ROOT / 'migrations/0007_add_snapshot_ts_index.sql').read_text())
        migration = (ROOT / 'migrations/0008_reduce_snapshot_reads.sql').read_text()
        db.executescript(migration)
        db.executescript(migration)  # safe to reapply independently of migration tracking
        for (sql, args, index), expected in zip(queries, before):
            self.assertEqual(db.execute(sql, args).fetchall(), expected)
            plan = str(db.execute('EXPLAIN QUERY PLAN ' + sql, args).fetchall())
            self.assertIn('USING COVERING INDEX ' + index, plan)
            self.assertNotIn('TEMP B-TREE', plan)
        db.close()
