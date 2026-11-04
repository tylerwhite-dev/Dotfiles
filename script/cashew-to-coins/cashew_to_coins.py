#!/usr/bin/env python3
"""Convert a Cashew CSV export to the six-column 5 Coins CSV format."""
import argparse
import csv
from datetime import datetime
from decimal import Decimal, InvalidOperation
from pathlib import Path
import sys

# Source export fields required for conversion.
REQUIRED = {'amount', 'amount unpaid', 'currency', 'title', 'note', 'date', 'type', 'category name'}


def convert(source: Path, destination: Path) -> tuple[int, int]:
    if source.resolve() == destination.resolve():
        raise ValueError('Input and output must be different files.')
    converted = []
    planned = 0
    # utf-8-sig reads CSV files with or without a BOM.
    with source.open(encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f)
        missing = REQUIRED - set(reader.fieldnames or [])
        if missing:
            raise ValueError('Missing columns: ' + ', '.join(sorted(missing)))
        for line, row in enumerate(reader, start=2):
            try:
                # Skip planned payments instead of importing them as completed transactions.
                if row['type'] == 'upcoming':
                    planned += 1
                    continue
                date = datetime.strptime(row['date'], '%Y-%m-%d %H:%M:%S.%f')
                # Use the unpaid amount when the amount field is empty.
                raw_amount = row['amount'].strip() or row['amount unpaid'].strip()
                amount = Decimal(raw_amount)
                if not amount.is_finite() or amount != amount.to_integral_value():
                    raise ValueError('Expected a whole-number amount')
                if not row['category name'].strip() or not row['currency'].strip():
                    raise ValueError('Category and currency must not be empty')
                if row['type'] not in ('default', 'upcoming'):
                    raise ValueError('Unknown transaction type: ' + row['type'])
                # Combine the title and note into the 5 Coins notes field.
                description = '; '.join(s.strip() for s in (row['title'], row['note']) if s.strip())
                # Copy the date without timezone conversion; Z matches the 5 Coins format.
                # Include the amount sign without thousands separators; use an exchange rate of 1.
                converted.append([
                    date.strftime('%Y-%m-%dT%H:%M:%SZ'),
                    row['category name'],
                    f'{int(amount):+d}',
                    description,
                    row['currency'],
                    '1.0000',
                ])
            except (ValueError, InvalidOperation, AttributeError, TypeError) as exc:
                raise ValueError(f'Invalid data on CSV line {line}: {exc}') from exc
    # Validate all rows before creating the file, and do not overwrite an existing file.
    if destination.exists():
        raise FileExistsError(f'Output already exists: {destination}')
    with destination.open('x', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL, lineterminator='\n')
        # The importer treats the first row as column headers.
        writer.writerow(['Date', 'Category', 'Amount', 'Notes', 'Currency', 'Exchange Rate'])
        writer.writerows(converted)
    return len(converted), planned


def output_path(source: Path) -> Path:
    # Save next to the source file and add a suffix if the name is already taken.
    base = source.with_name(source.stem + '_5coins.csv')
    candidate = base
    index = 2
    while candidate.exists():
        candidate = base.with_name(f'{base.stem}_{index}{base.suffix}')
        index += 1
    return candidate


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path, help='Cashew export CSV')
    args = parser.parse_args()
    try:
        destination = output_path(args.input)
        count, planned = convert(args.input, destination)
    except (OSError, ValueError, csv.Error) as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 1
    print(f'Converted {count} transactions, excluded {planned} planned. Output: {destination}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
