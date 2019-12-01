require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker
#    RecordResult = Struct.new(:success?, :expense_id, :error_message)
    
    RSpec.describe API do
        include Rack::Test::Methods
        
        def app
            API.new(ledger: ledger)
        end
        
        let(:ledger) { instance_double('ExpenseTracker::Ledger')}
        let(:parsed) { JSON.parse(last_response.body) }

        
        describe 'POST /expenses' do
            context 'when the expense is successfully recorded' do
                let(:expense) { { 'some' => 'data' } }
                before do
                    allow(ledger).to receive(:record)
                        .with(expense)
                        .and_return(RecordResult.new(true, 417, nil))
                    post '/expenses', JSON.generate(expense)
                end

                it 'returns the expense id' do
                    expect(parsed).to include('expense_id' => 417)
                end
                it 'responds with 200 (OK)' do
                    expect(last_response.status).to eq(200)
                end
            end
            context 'when the expense fails validation' do
                let(:expense) { { 'some' => 'data' } }
                before do
                    allow(ledger).to receive(:record)
                        .with(expense)
                        .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
                    post '/expenses', JSON.generate(expense)
                end
                it 'returns an error message' do
                    expect(parsed).to include('error' => 'Expense incomplete')
                end 
                it 'responds with a 422 (unprocessable entity)' do
                    expect(last_response.status).to eq(422)
                end
            end
        end
        describe 'GET /expenses/:date' do
            context 'when expenses exist on the given date' do
                before do
                    allow(ledger).to receive(:expenses_on)
                        .with('2017-06-12')
                        .and_return(['expense_1', 'expense_2'])
                end

                it 'returns the expense records as JSON' do
                    get '/expenses/2017-06-12'
                    expect(parsed).to eq(['expense_1', 'expense_2'])
                end
                it 'responds with a 200 (OK)' do
                    get '/expenses/2017-06-12'
                    expect(last_response.status).to eq(200)
                end
            end
            
            context 'when there are no expenses on the given date' do
                before do
                    allow(ledger).to receive(:expenses_on)
                    .with('2017-06-12')
                    .and_return([]) 
                end
                it 'returns an empty array as JSON' do
                  get '/expenses/2017-06-12'
                  
                  expect(parsed).to eq([])
                end

                it 'responds with a 200 (OK)' do
                    get '/expenses/2017-06-12'
                    expect(last_response.status).to eq(200)            
                end
            end
        end
    end
end
