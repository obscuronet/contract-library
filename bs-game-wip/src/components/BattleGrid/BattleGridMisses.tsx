import { useMemo } from 'react';

import { Container } from '@pixi/react';

import { useBattleGridStore } from '@/stores/battleGridStore';

import BattleGridCell from './BattleGridCell';

export default function BattleGridMisses() {
    const missedCells = useBattleGridStore((state) => state.missedCells);

    const revealedGridCells = useMemo(
        () =>
            missedCells.map(({ row, col, x, y }) => (
                <BattleGridCell
                    key={`${row}-${col}`}
                    x={x}
                    y={y}
                    row={row}
                    col={col}
                    state="MISSED"
                />
            )),
        [missedCells]
    );

    return <Container>{revealedGridCells}</Container>;
}
