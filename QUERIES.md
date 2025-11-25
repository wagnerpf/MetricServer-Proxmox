# Queries Flux - Exemplos para InfluxDB

Este arquivo contém exemplos de queries Flux para consultar dados no InfluxDB.

## Execução de Queries

### Via Dashboard Grafana
1. Abra um painel vazio
2. Selecione datasource "InfluxDB-Proxmox"
3. Clique em "Edit" do painel
4. Cole a query Flux

### Via CLI Docker
```bash
docker-compose exec influxdb influx query 'from(bucket:"proxmox-metrics") |> range(start:-1h)'
```

### Via API HTTP
```bash
curl -X POST http://localhost:8086/api/v2/query \
  -H "Authorization: Token YOUR_TOKEN" \
  -H "Content-type: application/vnd.flux" \
  -d 'from(bucket:"proxmox-metrics") |> range(start:-1h) |> limit(n:10)'
```

---

## Queries de Exemplo

### 1. Uso de CPU (Últimas 24 horas)

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")
  |> mean()
```

### 2. Memória Usada (Últimas 7 dias)

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "mem" and r._field == "used")
  |> window(every: 1h)
  |> mean()
```

### 3. Uso de Disco (Hosts específicos)

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => 
      r._measurement == "disk" and 
      r._field == "used_percent" and
      r.host == "proxmox-host-01"
    )
  |> last()
```

### 4. Tráfego de Rede (Últimas 12 horas)

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -12h)
  |> filter(fn: (r) => 
      r._measurement == "net" and 
      (r._field == "bytes_sent" or r._field == "bytes_recv")
    )
  |> derivative(unit: 1m)
```

### 5. Top 5 Processos por CPU

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "processes" and r._field == "cpu_percent")
  |> sort(columns: ["_value"], desc: true)
  |> limit(n: 5)
```

### 6. Alertas - CPU acima de 80%

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => 
      r._measurement == "cpu" and 
      r._field == "usage_percent" and
      r._value > 80.0
    )
  |> yield(name: "cpu_high")
```

### 7. Comparação com período anterior

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")
  |> group(columns: ["_time"])
  |> window(every: 1d)
  |> mean()
```

### 8. Dados faltando (últimas 6 horas)

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -6h)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> group(columns: ["_time"], mode: "by")
  |> count()
  |> filter(fn: (r) => r._value == 0)
```

### 9. Taxa de mudança (derivada) - CPU

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")
  |> derivative(unit: 1m)  // Taxa de mudança por minuto
  |> abs()
```

### 10. Múltiplas métricas combinadas

```flux
data_cpu = from(bucket: "proxmox-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")

data_mem = from(bucket: "proxmox-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "mem" and r._field == "used_percent")

union(tables: [data_cpu, data_mem])
  |> sort(columns: ["_time"])
```

### 11. Agregação por host

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")
  |> group(columns: ["host"])
  |> mean()
```

### 12. Percentil de resposta

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -7d)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")
  |> quantile(q: 0.95)  // 95º percentil
```

### 13. Mudança de estado (threshold crossing)

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")
  |> map(fn: (r) => ({r with status: if r._value > 75.0 then "crítico" else "normal"}))
```

### 14. Diferença entre medições consecutivas

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")
  |> difference()  // Diferença entre pontos consecutivos
```

### 15. Últimos 10 registros

```flux
from(bucket: "proxmox-metrics")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_percent")
  |> sort(columns: ["_time"], desc: true)
  |> limit(n: 10)
```

---

## Funções Úteis do Flux

| Função | Descrição | Exemplo |
|--------|-----------|---------|
| `range()` | Define intervalo de tempo | `range(start: -24h, stop: now())` |
| `filter()` | Filtra dados | `filter(fn: (r) => r._value > 50)` |
| `group()` | Agrupa dados | `group(columns: ["host"])` |
| `mean()` | Calcula média | `mean()` |
| `max()` | Valor máximo | `max()` |
| `min()` | Valor mínimo | `min()` |
| `sum()` | Soma | `sum()` |
| `count()` | Conta registros | `count()` |
| `derivative()` | Taxa de mudança | `derivative(unit: 1m)` |
| `window()` | Agrupa por período | `window(every: 1h)` |
| `sort()` | Ordena | `sort(columns: ["_time"])` |
| `limit()` | Limita resultado | `limit(n: 10)` |
| `map()` | Transforma dados | `map(fn: (r) => ({r with new: r._value * 2}))` |
| `quantile()` | Calcula percentil | `quantile(q: 0.95)` |
| `last()` | Último valor | `last()` |
| `first()` | Primeiro valor | `first()` |

---

## Troubleshooting de Queries

### Query não retorna dados
```flux
// Verificar se há dados
from(bucket: "proxmox-metrics")
  |> range(start: -1d)
  |> group(columns: ["_measurement"])
  |> count()  // Mostra quantidade por medida
```

### Testar filtro
```flux
// Listar todas as medições disponíveis
from(bucket: "proxmox-metrics")
  |> range(start: -1d)
  |> group(columns: ["_measurement"])
  |> first()
  |> keep(columns: ["_measurement"])
```

### Debug de campos
```flux
// Listar todos os campos
from(bucket: "proxmox-metrics")
  |> range(start: -1d)
  |> filter(fn: (r) => r._measurement == "cpu")
  |> group(columns: ["_field"])
  |> first()
  |> keep(columns: ["_field"])
```

---

## Dicas de Performance

1. **Use range() apropriadamente**: Não consulte dados muito antigos desnecessariamente
2. **Filtre cedo**: Use `filter()` logo após `range()`
3. **Agrupe inteligentemente**: Minimize grupos desnecessários
4. **Use window()**: Para séries temporais, use window para agregação
5. **Evite N+1**: Combine múltiplas queries em uma quando possível

---

## Documentação Oficial

- [Flux Language Reference](https://docs.influxdata.com/flux/v0.x/language/)
- [InfluxDB Query Guide](https://docs.influxdata.com/influxdb/v2.0/query-data/)
