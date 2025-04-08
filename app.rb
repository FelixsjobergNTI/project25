require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions


get('/') do
  slim(:start)
end


get('/register') do
  slim(:register)
end


post('/register') do
  username = params[:username]
  password = params[:password]

  password_digest = BCrypt::Password.create(password)

  db = SQLite3::Database.new("db/database.db")
  db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, password_digest])
  redirect('/login')
end


get('/login') do
  slim(:login)
end


post('/login') do
  username = params[:username]
  password = params[:password]

  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  user = db.execute("SELECT * FROM users WHERE username = ?", [username]).first

  if user && BCrypt::Password.new(user["password"]) == password
    session[:user_id] = user["id"]
    redirect('/casino')
  else
    "Fel användarnamn eller lösenord"
  end
end


get('/logout') do
  session.clear
  redirect('/')
end


get('/casino') do
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM games")
  slim(:index, locals: { games: result })
end


get('/casino/new') do
  if session[:user_id].nil?
    redirect('/login')
  end
  slim(:new)
end


post('/casino/new') do
  user_id = session[:user_id]
  bet = params[:bet].to_i
  result = ["Vinst", "Förlust"].sample
  db = SQLite3::Database.new("db/database.db")
  db.execute("INSERT INTO games (user_id, bet, result) VALUES (?, ?, ?)", [user_id, bet, result])
  redirect('/casino')
end


post('/casino/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/database.db")
  db.execute("DELETE FROM games WHERE id = ?", [id])
  redirect("/casino")
end

post('/casino/:id/update') do
  id = params[:id].to_i
  bet = params[:bet].to_i
  result = params[:result]
  db = SQLite3::Database.new("db/database.db")
  db.execute("UPDATE games SET bet = ?, result = ? WHERE id = ?", [bet, result, id])
  redirect('/casino')
end

get('/casino/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM games WHERE id = ?", [id]).first
  slim(:edit, locals: { result: result })
end

get('/casino/:id') do
  id = params[:id].to_i
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM games WHERE id = ?", id).first
  user = db.execute("SELECT username FROM users WHERE id = (SELECT user_id FROM games WHERE id = ?)", id).first
  slim(:show, locals: { result: result, user: user })
end