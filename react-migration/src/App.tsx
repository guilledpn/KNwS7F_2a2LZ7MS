import { useState } from 'react';
import type { ScreenId } from './types';
import { ContactList } from './components/ContactList';
import { Stats } from './components/Stats';
import { ImportView } from './components/ImportView';
import { Settings } from './components/Settings';
import { SprintChip } from './components/SprintChip';

const titles: Record<ScreenId, string> = {
  contacts: 'Contactos',
  stats: 'Stats',
  import: 'Importar',
  settings: 'Ajustes'
};

export function App() {
  const [screen, setScreen] = useState<ScreenId>('contacts');

  return (
    <div className="app-shell" data-version="App_llamados_react_migration_hito_1">
      <header className="topbar">
        <div className="top-title">{titles[screen]}</div>
        <div className="top-spacer" />
        <SprintChip />
        <button className="goal-chip" onClick={() => setScreen('stats')}>Hoy 0/0</button>
        <button className="icon-btn" onClick={() => setScreen('settings')} aria-label="Ajustes">⚙</button>
      </header>

      <main className="screens">
        {screen === 'contacts' && <ContactList />}
        {screen === 'stats' && <Stats />}
        {screen === 'import' && <ImportView />}
        {screen === 'settings' && <Settings />}
      </main>

      <nav className="bottom-nav">
        <button className={screen === 'contacts' ? 'nav-btn on' : 'nav-btn'} onClick={() => setScreen('contacts')}>Contactos</button>
        <button className={screen === 'stats' ? 'nav-btn on' : 'nav-btn'} onClick={() => setScreen('stats')}>Stats</button>
        <button className={screen === 'import' ? 'nav-btn on' : 'nav-btn'} onClick={() => setScreen('import')}>Importar</button>
      </nav>
    </div>
  );
}
