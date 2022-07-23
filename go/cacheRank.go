package isuports

import (
	"fmt"
	"sync"
)

type MutexCompetitionRankMap struct {
	v   map[string][]CompetitionRank
	mux sync.RWMutex
}

func newMutexCompetitionRankMap() *MutexCompetitionRankMap {
	return &MutexCompetitionRankMap{
		v:   make(map[string][]CompetitionRank, 1000),
		mux: sync.RWMutex{},
	}
}

func (m *MutexCompetitionRankMap) Get(tenantId int64, competitionId string) []CompetitionRank {
	tcid := fmt.Sprintf("%d_%s", tenantId, competitionId)
	m.mux.RLock()
	defer m.mux.RUnlock()
	if v, ok := m.v[tcid]; ok {
		return v
	} else {
		return nil
	}
}

// 上書き
func (m *MutexCompetitionRankMap) Set(tenantId int64, competitionId string, rank []CompetitionRank) {
	tcid := fmt.Sprintf("%d_%s", tenantId, competitionId)
	m.mux.Lock()
	m.v[tcid] = rank
	m.mux.Unlock()
}
