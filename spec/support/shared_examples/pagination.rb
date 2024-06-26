# frozen_string_literal: true

shared_examples 'it is a paginated enumerator' do |operation|
  let(:num_items) { 5 }
  let(:ids) { Array.new(num_items) { SecureRandom.uuid } }
  let(:data) { ids.map { |id| create_model.call(id) } }
  let(:expected_items) { data.map { |model| item_klass.new(model) } }

  it 'returns an enumerator' do
    expect(enumerator).to be_a(Enumerator)
  end

  it 'does not fetch data until evaluated' do
    expect(api).not_to receive(:"list_#{operation}")

    enumerator
  end

  context 'when it is evaluated' do
    let(:resource_list) { resource_list_klass.new(data: data) }

    before do
      data.each_with_index do |model, i|
        allow(item_klass)
          .to receive(:new)
          .with(*[model, item_initialize_args].compact)
          .and_return(expected_items[i])
      end

      allow(api)
        .to receive(:"list_#{operation}")
        .with(*fetch_params.call(nil))
        .and_return(resource_list)
        .once
    end

    it 'returns the total count' do
      expect(enumerator.count).to eq(num_items)
    end

    it 'returns all the items' do
      expect(enumerator.to_a).to eq(expected_items)
    end

    it 'allows enumeration of the collection' do
      enumerator.each do |item|
        expect(item).to be_a(item_klass)
      end
    end

    it 'fetches the first page' do
      expect(api)
        .to receive(:"list_#{operation}")
        .with(*fetch_params.call(nil))
        .once

      enumerator.to_a
    end
  end

  context 'when there are multiple pages worth of data' do
    let(:num_items) { 150 }
    let(:next_page) { 'page_token_2' }
    let(:resource_list1) do
      resource_list_klass.new(data: data.take(100), has_more: true, next_page: next_page)
    end
    let(:resource_list2) do
      resource_list_klass.new(data: data.drop(100), has_more: false, next_page: nil)
    end

    before do
      allow(api)
        .to receive(:"list_#{operation}")
        .with(*fetch_params.call(nil))
        .and_return(resource_list1)
        .once
    end

    context 'when only taking elements from the first page' do
      it 'only fetches the first page' do
        expect(api)
          .to receive(:"list_#{operation}")
          .with(*fetch_params.call(nil))
          .once

        enumerator.first
      end

      it 'returns the correct number of items' do
        expect(enumerator.take(5).count).to eq(5)
      end
    end

    context 'when iterating over all items' do
      before do
        allow(api)
          .to receive(:"list_#{operation}")
          .with(*fetch_params.call(next_page))
          .and_return(resource_list2)
          .once
      end

      it 'returns the total count' do
        expect(enumerator.count).to eq(num_items)
      end

      it 'allows enumeration of the collection' do
        enumerator.each do |item|
          expect(item).to be_a(item_klass)
        end
      end

      it 'fetches all pages' do
        expect(api)
          .to receive(:"list_#{operation}")
          .with(*fetch_params.call(nil))
          .once

        expect(api)
          .to receive(:"list_#{operation}")
          .with(*fetch_params.call(next_page))
          .once

        enumerator.to_a
      end
    end
  end
end
