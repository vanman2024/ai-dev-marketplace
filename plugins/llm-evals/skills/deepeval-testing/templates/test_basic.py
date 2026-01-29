# test_basic.py - Basic DeepEval tests
from deepeval import assert_test
from deepeval.test_case import LLMTestCase
from deepeval.metrics import AnswerRelevancyMetric

def test_answer_relevancy():
    test_case = LLMTestCase(
        input="What is the capital of France?",
        actual_output="Paris is the capital of France."
    )
    metric = AnswerRelevancyMetric(threshold=0.7)
    assert_test(test_case, [metric])
