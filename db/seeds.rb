User.create(username:'system', display_name: 'System', active: false)
p "Created seed users."

Group.create(name:'Default', slack_channel: '#general', default: true)
p "Created seed group."

Reward.create(name:'Team T-shirt', cost: 180, stock_count: Reward::INFINITE_STOCK, visible: true)
Reward.create(name:'2 Movie tickets', cost: 300, stock_count: 80, visible: true)
p "Created seed rewards."
