# Chain Workflow Examples

Real-world scenarios using Celery chains for sequential task execution.

## Example 1: Data Processing Pipeline

**Scenario:** Process raw data through multiple transformation stages sequentially.

```python
from celery import chain

# Sequential data pipeline
workflow = chain(
    fetch_raw_data.s('source_api'),
    validate_schema.s(),
    clean_data.s(),
    transform_format.s(),
    save_to_database.s()
)

result = workflow.apply_async()
processed_data = result.get(timeout=60)
```

**Why chains:** Each stage depends on the previous stage's output. Data flows from fetch → validate → clean → transform → save.

## Example 2: User Onboarding Flow

**Scenario:** Execute sequential steps for new user registration.

```python
from celery import chain

def onboard_new_user(user_data):
    """Complete user onboarding workflow"""
    workflow = chain(
        # Step 1: Create account
        create_user_account.s(user_data),

        # Step 2: Send welcome email (receives user_id from step 1)
        send_welcome_email.s(),

        # Step 3: Setup default preferences
        initialize_preferences.s(),

        # Step 4: Send to CRM (immutable - doesn't need user_id)
        sync_to_crm.si(user_data['email'])
    )

    return workflow.apply_async()
```

**Key points:**
- Steps 1-3 pass results forward (user_id flows through pipeline)
- Step 4 uses `.si()` to execute independently with original email

## Example 3: Report Generation

**Scenario:** Generate analytics report through multiple phases.

```python
from celery import chain

def generate_monthly_report(month, year):
    """Generate comprehensive monthly report"""
    workflow = chain(
        # Phase 1: Collect data
        collect_sales_data.s(month, year),

        # Phase 2: Analyze data
        calculate_metrics.s(),

        # Phase 3: Generate charts
        create_visualizations.s(),

        # Phase 4: Compile report
        compile_report_pdf.s(),

        # Phase 5: Distribute (independent)
        send_report_to_stakeholders.si(f"report_{month}_{year}.pdf")
    )

    result = workflow.apply_async()
    return result.get(timeout=300)
```

**Performance:** Sequential execution ensures each phase completes before next starts.

## Example 4: Order Fulfillment

**Scenario:** Process e-commerce order through fulfillment stages.

```python
from celery import chain

def fulfill_order(order_id):
    """Execute order fulfillment workflow"""
    workflow = chain(
        # Validate order
        validate_order.s(order_id),

        # Check inventory
        check_inventory.s(),

        # Reserve items
        reserve_inventory.s(),

        # Process payment
        charge_customer.s(),

        # Create shipment
        create_shipment_label.s(),

        # Notify customer (independent notification)
        send_order_confirmation.si(order_id)
    )

    # With error handling
    workflow.on_error(handle_order_error.s(order_id))

    return workflow.apply_async()
```

**Error handling:** If any step fails (e.g., payment), error handler can rollback inventory reservation.

## Example 5: Video Processing Pipeline

**Scenario:** Process uploaded video through encoding stages.

```python
from celery import chain

def process_video(video_id):
    """Multi-stage video processing"""
    workflow = chain(
        # Download source
        download_source_video.s(video_id),

        # Extract metadata
        extract_video_metadata.s(),

        # Generate thumbnail
        create_thumbnail.s(),

        # Encode formats
        encode_720p.s(),

        # Upload results
        upload_to_cdn.s(),

        # Update database (immutable)
        update_video_status.si(video_id, 'completed')
    )

    # Long-running workflow
    result = workflow.apply_async()
    return result.get(timeout=600)
```

**Timeout consideration:** Video processing takes time, use appropriate timeout values.

## Example 6: ETL with Validation

**Scenario:** Extract, transform, load with validation steps.

```python
from celery import chain

def etl_with_validation(source_config):
    """ETL pipeline with validation gates"""
    workflow = chain(
        # Extract
        extract_from_source.s(source_config),

        # Validate extraction
        validate_extraction.s(),

        # Transform
        apply_transformations.s(),

        # Validate transformations
        validate_transformations.s(),

        # Load
        load_to_warehouse.s(),

        # Verify load
        verify_data_integrity.s()
    )

    # Error handling
    workflow.on_error(log_etl_error.s(source_config['name']))

    return workflow.apply_async()
```

**Validation gates:** Each major phase has validation to catch errors early.

## Example 7: Partial Application Pattern

**Scenario:** Reuse chain with different inputs.

```python
from celery import chain

# Create reusable processing chain
processing_pipeline = chain(
    normalize_data.s(),
    apply_business_rules.s(),
    validate_output.s(),
    save_result.s()
)

# Apply to different datasets
dataset_a_result = processing_pipeline.clone(args=(dataset_a,)).apply_async()
dataset_b_result = processing_pipeline.clone(args=(dataset_b,)).apply_async()
dataset_c_result = processing_pipeline.clone(args=(dataset_c,)).apply_async()

# Wait for all
results = [r.get(timeout=60) for r in [dataset_a_result, dataset_b_result, dataset_c_result]]
```

**Reusability:** Define chain once, apply to multiple inputs.

## Example 8: Conditional Chain

**Scenario:** Different processing paths based on data characteristics.

```python
from celery import chain

@app.task
def route_processing(data):
    """Route to appropriate processing chain"""
    if data['type'] == 'urgent':
        return chain(
            fast_validation.s(data),
            priority_processing.s(),
            immediate_notification.s()
        ).apply_async()
    else:
        return chain(
            thorough_validation.s(data),
            standard_processing.s(),
            batch_notification.s()
        ).apply_async()

# Execute
result = route_processing.s(incoming_data).apply_async()
```

**Conditional logic:** Choose chain based on data attributes.

## Best Practices from Examples

1. **Use `.si()` for independent tasks:** Tasks that don't need previous results
2. **Add error handlers:** Use `.on_error()` for critical workflows
3. **Set appropriate timeouts:** Long workflows need longer `.get(timeout=)`
4. **Validate between stages:** Catch errors early in pipeline
5. **Make chains reusable:** Use `.clone()` for repeated patterns
6. **Keep chains focused:** Don't make chains too long (>10 steps)

## Anti-Patterns to Avoid

❌ **Mixing parallel and sequential:** Use groups/chords for parallel work
❌ **Blocking in tasks:** Don't call `.get()` inside task definitions
❌ **No error handling:** Always consider failure scenarios
❌ **Ignoring results:** Chains need results to flow between tasks

## Performance Considerations

- **Sequential execution:** Each task waits for previous to complete
- **Network overhead:** Each task is a separate message
- **Memory:** Results stored in backend between tasks
- **Time limits:** Set `soft_time_limit` and `time_limit` for long tasks

## Monitoring

```python
# Track chain progress
result = workflow.apply_async()

# Check status
print(f"State: {result.state}")

# Get intermediate results (if result_extended=True)
print(f"Parent: {result.parent}")

# Wait with progress
while not result.ready():
    print("Processing...")
    time.sleep(1)

final_result = result.get()
```
